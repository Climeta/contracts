// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import {VotingStorage} from "../storage/VotingStorage.sol";
import {IVoting} from "../interfaces/IVoting.sol";
import {DelMundo} from "../token/DelMundo.sol";
import {Rayward} from "../token/Rayward.sol";
import {RayWallet} from "../RayWallet.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract VotingFacet is IVoting{
    ClimetaStorage internal s;


    constructor(){
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        vs.nextProposalId= 1;
        vs.votingRound = 1;    }

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

    /// @notice gets the amount of raywards given for the voting round.
    function getVotingRoundReward() external returns(uint256)  {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        return vs.votingRoundReward;
    }
    /// @notice Sets the amount of raywards given for the voting round. Can only be called by Admins
    /// @param _rewardAmount The new reward amount
    function setVotingRoundReward(uint256 _rewardAmount) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        emit Climeta__VotingRewardChanged(_rewardAmount);
        vs.votingRoundReward = _rewardAmount;
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
        if (vs.proposals[_propId].votingRound != m_votingRound) {
            revert Climeta__ProposalNotInRound();
        }

        // Membership test
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
        (_ret, _addr, _tokenId) = RayWallet(payable(_caller)).token();
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

        // Send Raywards TODO this should move to endVote because we need to work out who gets what
        Rayward(s.raywardAddress).transferFrom(s.rayWalletAddress, _caller, vs.votingRoundReward);
    }

    /// @notice Checks the ERC20 against list of allowed tokens
    /// @param _token The token to check
    function isAllowedToken(address _token) internal view returns(bool) {
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        uint256 length = vs.allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (vs.allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    /// @notice Adds an ERC20 to the list of allowed tokens
    /// @param _token The allowed token to add
    function addAllowedToken(address _token) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        if (!isAllowedToken(_token)) {
            vs.allowedTokens.push() = _token;
            emit Climeta__TokenApproved(_token);
        }
    }

    /// @notice Removes an ERC20 from the list of allowed tokens
    /// Cannot remove if there is still value left in the treasury.
    /// @param _token The allowed token to add
    function removeAllowedToken(address _token) external {
        LibDiamond.enforceIsContractOwner();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        if (IERC20(_token).balanceOf(address(this)) > 0) {
            revert Climeta__ValueStillInContract();
        }

        uint256 numberOfTokens = vs.allowedTokens.length;
        // remove from array of proposals for this voting round
        for (uint256 i=0; i < numberOfTokens;i++) {
            if (vs.allowedTokens[i] == _token) {
                for (uint256 j=i; j + 1 < numberOfTokens ; j++ ) {
                    vs.allowedTokens[j] = vs.allowedTokens[j+1];
                }
                vs.allowedTokens.pop();
                emit Climeta__TokenRevoked(address(_token));
                return;
            }
        }
    }

    /**
    * @dev Allows beneficiaries to claim their funds
    * This only allows the owner of the beneficiary address to withdraw the funds.
    *
    */
    function withdraw() external {
        //ERC20 withdrawals
        uint256 approvedErc20Length = s.allowedTokens.length;
        for (uint256 i=0; i < approvedErc20Length; i++ ) {
            uint256 amount = s.erc20Withdrawls[msg.sender][s.allowedTokens[i]];
            if (amount > 0) {
                s.erc20Withdrawls[msg.sender][s.allowedTokens[i]] = 0;
                emit Climeta__ERC20Payout(msg.sender, s.allowedTokens[i], amount);
                IERC20(s.allowedTokens[i]).transfer(msg.sender, amount);
            }
        }

        // ETH withdrawals
        uint256 amountETH = s.withdrawls[msg.sender];
        if (amountETH > 0) {
            s.withdrawls[msg.sender] = 0;
            emit Climeta__Payout(msg.sender, amountETH);
            payable(msg.sender).call{value: amountETH}("");
        }
    }
}
