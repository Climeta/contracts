// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {VotingStorage} from "../storage/VotingStorage.sol";

contract VotingFacet {
    ClimetaStorage internal s;

    // Events
    /// @notice Emitted when a payout is made
    /// @param _to The address receiving the payout
    /// @param _amount The amount of the payout
    event ClimetaCore__Payout(address _to, uint256 _amount);

    /// @notice Emitted when an ERC20 payout is made
    /// @param _to The address receiving the payout
    /// @param _token The address of the ERC20 being paid out
    /// @param _amount The amount of the payout
    event ClimetaCore__ERC20Payout(address _to, address _token, uint256 _amount);

    /// @notice Emitted when a vote is cast
    /// @param _votingNFT The NFT used to vote
    /// @param _proposalId The ID of the proposal being voted on
    event ClimetaCore__Vote(uint256 _votingNFT, uint256 _proposalId);

    /// @notice Emitted when a new proposal is added
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the new proposal
    event ClimetaCore__NewProposal(address _benefactor, uint256 _proposalId);

    /// @notice Emitted when a proposal is changed
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the proposal being changed
    event ClimetaCore__ChangeProposal(address _benefactor, uint256 _proposalId);

    /// @notice Emitted when a proposal is included in a voting round
    /// @param _votingRound The voting round in which the proposal was included
    /// @param _proposalId The ID of the proposal being included
    event ClimetaCore__ProposalIncluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a proposal is excluded from a voting round
    /// @param _votingRound The voting round from which the proposal was excluded
    /// @param _proposalId The ID of the proposal being excluded
    event ClimetaCore__ProposalExcluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a new beneficiary is added
    /// @param _beneficiary The address of the new beneficiary
    /// @param name The name of the new beneficiary
    event ClimetaCore__NewBeneficiary(address _beneficiary, string name);

    /// @notice Emitted when a beneficiary is removed
    /// @param _beneficiary The address of the beneficiary being removed
    event ClimetaCore__RemovedBeneficiary(address _beneficiary);

    /// @notice Emitted when a token is approved for use as treasury token
    /// @param _token The address of the ERC20 token added
    event ClimetaCore__TokenApproved(address _token);

    /// @notice Emitted when a token is revoked for use as treasury token
    /// @param _token The address of the ERC20 token removed
    event ClimetaCore__TokenRevoked(address _token);

    // Errors
    error ClimetaCore__CannotRemoveLastAdmin();
    error ClimetaCore__NotAdmin();
    error ClimetaCore__NotRayWallet();
    error ClimetaCore__NotAMember();
    error ClimetaCore__NotApproved();
    error ClimetaCore__NoProposal();
    error ClimetaCore__AlreadyInRound();
    error ClimetaCore__ProposalNotInRound();
    error ClimetaCore__AlreadyVoted();
    error ClimetaCore__NoVotes();
    error ClimetaCore__NotFromAuthContract();
    error ClimetaCore__NoFundsToWithdraw();
    error ClimetaCore__ProposalHasVotes();
    error ClimetaCore__ValueStillInContract();


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



}
