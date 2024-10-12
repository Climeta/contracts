// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import {Constants} from "../lib/Constants.sol";
import {VotingStorage} from "../storage/VotingStorage.sol";
import {IVoting} from "../interfaces/IVoting.sol";
import {DelMundo} from "../token/DelMundo.sol";
import {Rayward} from "../token/Rayward.sol";
import {Raycognition} from "../token/Raycognition.sol";
import {IRayWallet} from "../interfaces/IRayWallet.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC6551Registry} from "../../lib/tokenbound/lib/erc6551/src/ERC6551Registry.sol";

contract VotingFacet is IVoting{
    ClimetaStorage internal s;

    function init() external {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        vs.nextProposalId= 1;
        vs.votingRound = 1;
    }

    constructor(){
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function votingFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    function getVotingRound() external view returns(uint256) {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        return vs.votingRound;
    }


    // Allow the adding of proposals by the Admin group only
    /// @notice Adds a new beneficiary
    /// @param _beneficiary The address of the new beneficiary
    function addProposal(address _beneficiary, string calldata _proposalURI) external returns(uint256) {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        emit Climeta__NewProposal(_beneficiary, vs.nextProposalId);
        vs.proposals[vs.nextProposalId] = _proposalURI;
        vs.proposalOwner[vs.nextProposalId] = _beneficiary;
        vs.nextProposalId++;
        return vs.nextProposalId - 1;
    }

    /// @notice Updates a proposal;
    /// @param _propId The proposal ID to update
    /// @param _proposalURI new URI of the proposal
    function updateProposalMetadata(uint256 _propId, string calldata _proposalURI) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        vs.proposals[_propId] = _proposalURI;
    }

    /**
    * @dev Proposals are submitted by the beneficiaries and then added to the voting round by the Admins
    * This is managed in 2 places on chain, the s_votingRoundProposals which is a mapping of the voting round to an array of prpoposals
    * and the s_proposals mapping which has the voting round the proposal is in stored directly against the proposal struct itself.
    *
    * @param _proposalId The ID of the proposal to add
    */
    function addProposalToVotingRound (uint256 _proposalId) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        if (vs.proposalOwner[_proposalId] == address(0)) {
            revert Climeta__NoProposal();
        }
        if (vs.proposalVotingRound[_proposalId] != 0) {
            revert Climeta__AlreadyInRound();
        }
        emit Climeta__ProposalIncluded(vs.votingRound, _proposalId);
        // Mark the proposal as in the current voting round
        vs.proposalVotingRound[_proposalId] = vs.votingRound;
        vs.votingRoundProposals[vs.votingRound].push(_proposalId);
    }


    /**
    * @dev Removal from voting round will be an exception use case, hence the less gas effective manner of removing as opposed to adding.
    * The bulk of the work is in removing from the proposal array for the voting round, but this array will only really be a handful of
    * proposals each time, it is not an unbounded array as such.
    *
    * @param _proposalId The ID of the proposal to remove
    */
    function removeProposalFromVotingRound (uint256 _proposalId) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        // retrieve from storage once
        uint256 m_votingRound = vs.votingRound;
        if (vs.proposalVotingRound[_proposalId] != m_votingRound) {
            revert Climeta__ProposalNotInRound();
        }
        // If the proposal already has votes - can't remove
        if (vs.votes[_proposalId].length != 0) {
            revert Climeta__ProposalHasVotes();
        }

        vs.proposalVotingRound[_proposalId] = 0;
//        vs.votingRoundProposals[vs.votingRound].push(_proposalId);

        uint256 numberOfProposals = vs.votingRoundProposals[m_votingRound].length;
        // remove from array of proposals for this voting round
        for (uint256 i=0; i < numberOfProposals;i++) {
            if (vs.votingRoundProposals[m_votingRound][i] == _proposalId) {
                for (uint256 j=i; j < numberOfProposals -1 ; j++ ) {
                    vs.votingRoundProposals[m_votingRound][j] = vs.votingRoundProposals[m_votingRound][j+1];
                }
                vs.votingRoundProposals[m_votingRound].pop();
                emit Climeta__ProposalExcluded(m_votingRound, _proposalId);
                return;
            }
        }
    }

    /**
    * @dev This is the core interaction in Climeta. The vote. We need to ensure that only members vote and that they can only vote once.
    * This function needs to be called by the wallet of the Del Mundo, not by the end user.
    *
    * The membership test gets the tokenid associated with the calling wallet and then validates chain, right del mundo contract
    * and that the tokenid is in the right range. We also ensure that the caller is a smart contract, not an end user wallet as first check.
    *
    * The rewards for voting are also directly sent out via this contract function to the caller. This contract has the permissions
    * and the allowances setup to send from Ray's wallet which holds the reward pool of Raywards.
    *
    * We also need to ensure that the proposal is in the current voting round.
    *
    * Votes are stored in a couple of places. We store the full list of del mundo token ids that have voted for each proposal
    * as well as a lookup mapping of voting round to del mundo to boolean as a quick check to avoid array lookups.
    *
    * Voting currently is an immutable operation, there is no undoing once voted.
    *
    * @param _propId The ID of the proposal to vote on
    */
    function castVote(uint256 _propId) external {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        uint256 m_votingRound = vs.votingRound;
        // require proposal to be part of voting _votingRound
        if (vs.proposalVotingRound[_propId] != m_votingRound) {
            revert Climeta__ProposalNotInRound();
        }

        // Membership test
        // TODO do a full review of this - its a crucial check of the system
        uint32 size;
        uint256 _tokenId;
        address _addr;
        uint256 _ret;
        address _caller = msg.sender;
        // Ensure caller is a smart contract (eg smart wallet for voting)
        assembly {
            size := extcodesize(_caller)
        }
        if (size == 0) {
            revert Climeta__NotRayWallet();
        }
        (_ret, _addr, _tokenId) = IRayWallet(payable(_caller)).token();
        // if _tokenId isn't valid (in range) and this isn't right chain and not the right contract, then not a valid member token.
        // Also, Ray himself (tokenId == 0) can't vote.
        if ((_tokenId <= 0) || (_tokenId > DelMundo(s.delMundoAddress).totalSupply()) || (_ret != block.chainid) || (_addr != s.delMundoAddress)) {
            revert Climeta__NotAMember();
        }

        // Ensure not already voted
        if (vs.votingRoundDelMundoVoters[m_votingRound][_tokenId] == true) {
            revert Climeta__AlreadyVoted();
        }

        // Add vote to vote history mapping and mark as voted to ensure single vote
        vs.votingRoundDelMundoVoters[m_votingRound][_tokenId] = true;
        vs.votes[_propId].push(_tokenId);
        emit Climeta__Vote(_tokenId, _propId);

        // Send Raywards
        // could do a minimum now and the rest at end?
        //Rayward(s.raywardAddress).transferFrom(s.rayWalletAddress, _caller, s.votingRoundReward);
    }

    /**
    * @dev Allows beneficiaries to claim their funds
    * This only allows the owner of the beneficiary address to withdraw the funds.
    *
    */
    function withdraw() external {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        //ERC20 withdrawals
        uint256 approvedErc20Length = s.allowedTokens.length;
        for (uint256 i=0; i < approvedErc20Length; i++ ) {
            uint256 amount = vs.erc20Withdrawals[msg.sender][s.allowedTokens[i]];
            if (amount > 0) {
                vs.erc20Withdrawals[msg.sender][s.allowedTokens[i]] = 0;
                emit Climeta__ERC20Payout(msg.sender, s.allowedTokens[i], amount);
                IERC20(s.allowedTokens[i]).transfer(msg.sender, amount);
            }
        }

        // ETH withdrawals
        uint256 amountETH = vs.withdrawals[msg.sender];
        if (amountETH > 0) {
            vs.withdrawals[msg.sender] = 0;
            emit Climeta__Payout(msg.sender, amountETH);
            payable(msg.sender).call{value: amountETH}("");
        }
    }

    /**
    * @dev Allows Climeta admins to push the funds directly to the beneficaries
    *
    * This is really for those beneficiaries that may not be able to withdraw themselves for whatever reason.
    * This does not give Climeta access to the voting funds, once marked as vote end, the only place the funds can go
    * is to the beneficiary.
    *
    * @param _beneficiary The ID of the charity to push the payment to
    */
    function pushPayment(address _beneficiary) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        //ERC20 withdrawals
        uint256 approvedErc20Length = s.allowedTokens.length;
        for (uint256 i=0; i < approvedErc20Length; i++ ) {
            uint256 amount = vs.erc20Withdrawals[_beneficiary][s.allowedTokens[i]];
            if (amount > 0) {
                vs.erc20Withdrawals[_beneficiary][s.allowedTokens[i]] = 0;
                emit Climeta__ERC20Payout(_beneficiary, s.allowedTokens[i], amount);
                IERC20(s.allowedTokens[i]).transfer(msg.sender, amount);
            }
        }

        // ETH withdrawals
        uint256 amountETH = vs.withdrawals[_beneficiary];
        if (amountETH > 0) {
            vs.withdrawals[_beneficiary] = 0;
            emit Climeta__Payout(_beneficiary, amountETH);
            payable(_beneficiary).call{value: amountETH}("");
        }
    }

    /**
    * @dev The ending of a voting round is a manual action performed by Climeta Admins. This may change moving forwards to be more autonomous.
    *
    * The fund is currently split into 2 pieces. The EVERYONE_PERCENTAGE ensures that ALL beneficiaries receive an even split of this percentage.
    * This is currently set to 10% at time of writing. The remaining 90% is then split based on the number of votes each proposal received.
    *
    * The actual funds are not actually sent out from this function though. What we do is add in what each beneficiary can withdraw
    * and add this to the s_withdrawls mapping. This is then pulled out by the beneficiary themselves. There is also an admin only function
    * which allows Climeta to push the funds individually from this contract to the beneficiary as a failsafe.
    *
    * The whole fund amount is allocated at this point, there should be nothing left.
    *
    * Going forwards this will become less centralised and more automated via timeboxing and other mechanisms, but for now
    * is fully under the control of Climeta.
    *
    * Once the voting round is concluded, the voting round counter is incremented and we begin again.
    *
    */
    function endVotingRound () external payable {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        uint256 totalVotes = 0;
        uint256 m_votingRound = vs.votingRound;
        uint256[] memory propIds = vs.votingRoundProposals[m_votingRound];
        uint256 propIdsLength = propIds.length;

        // find total number of votes for this round
        for (uint256 i = 0; i < propIdsLength; i++) {
            totalVotes += vs.votes[propIds[i]].length;
        }
        if (totalVotes == 0) {
            revert Climeta__NoVotes();
        }

        uint256 fundEthBalance = address(this).balance;
        // work out amount to send out to all according to EVERYONE_PERCENTAGE
        uint256 ethToAll = (fundEthBalance * Constants.EVERYONE_PERCENTAGE) / (propIdsLength*100);

        uint256 approvedErc20Length = s.allowedTokens.length;
        // Create an array of the amounts to go to each for each ERC20
        uint256[] memory erc20ToAll;
        for (uint256 i = 0; i < approvedErc20Length; i++) {
            erc20ToAll[i] = ( IERC20(s.allowedTokens[i]).balanceOf(address(this)) * Constants.EVERYONE_PERCENTAGE) / (propIdsLength*100);
        }

        // amount paid out is % of fund to each beneficiary
        // Total = amount everyone gets + remainder according to what % of the total vote this proposal received
        for (uint256 i = 0; i < propIdsLength; i++) {
            uint256 ethAmount;
            unchecked {ethAmount = (fundEthBalance * (100-Constants.EVERYONE_PERCENTAGE) * vs.votes[propIds[i]].length/totalVotes)/100 + ethToAll;}
            // Add to amount in case beneficiary has not withdrawn from previous rounds.
            vs.withdrawals[vs.proposalOwner[propIds[i]]] += ethAmount;

            for (uint256 j = 0; j < approvedErc20Length; j++) {
                uint256 erc20Amount;
                unchecked {erc20Amount = (IERC20(s.allowedTokens[j]).balanceOf(address(this)) * (100-Constants.EVERYONE_PERCENTAGE) * vs.votes[propIds[i]].length/totalVotes)/100 + erc20ToAll[j];}

                vs.erc20Withdrawals[vs.proposalOwner[propIds[i]]][s.allowedTokens[j]] += erc20Amount;
            }
        }

        processRewards(totalVotes);
        vs.votingRound++;
    }

    function processRewards(uint256 _totalVotes) internal {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        uint256 m_votingRound = vs.votingRound;
        uint256 voteCount = vs.votes[vs.votingRound].length;
        uint256 totalCognition = 0;
        for (uint256 i = 0; i < voteCount; i++) {
            uint256 delmundoId = vs.votes[m_votingRound][i];
            address delmundoWallet = IERC6551Registry(s.registryAddress).account(s.rayWalletAddress, '0x',block.chainid, s.delMundoAddress, delmundoId);
            totalCognition += Raycognition(s.raycognitionAddress).balanceOf(delmundoWallet);
        }
        for (uint256 i = 0; i < voteCount; i++) {
            uint256 delmundoId = vs.votes[m_votingRound][i];
            address delmundoWallet = IERC6551Registry(s.registryAddress).account(s.rayWalletAddress, '0x', block.chainid, s.delMundoAddress, delmundoId);
            uint256 raycognition = Raycognition(s.raycognitionAddress).balanceOf(delmundoWallet);
            address delmundoOwner = IRayWallet(payable(msg.sender)).owner();

            // Formula for Raywards = 50% split across all voters and rest split by proportion of raycognition
            uint256 rewardAmount = ((s.votingRoundReward / 2) / _totalVotes)  + ((s.votingRoundReward / 2) / (raycognition/totalCognition)  );
            try {
                Rayward(s.raywardAddress).transferFrom(s.rayWalletAddress, delmundoOwner, rewardAmount);
            } catch {
                //TODO - add Raywards to a withdrawal process.
            }
        }
    }
}
