// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IVoting {
    event Climeta__VotingRewardChanged(uint256 amount);
    // Events
    /// @notice Emitted when a payout is made
    /// @param _to The address receiving the payout
    /// @param _amount The amount of the payout
    event Climeta__Payout(address _to, uint256 _amount);

    /// @notice Emitted when an ERC20 payout is made
    /// @param _to The address receiving the payout
    /// @param _token The address of the ERC20 being paid out
    /// @param _amount The amount of the payout
    event Climeta__ERC20Payout(address _to, address _token, uint256 _amount);

    /// @notice Emitted when a vote is cast
    /// @param _votingNFT The NFT used to vote
    /// @param _proposalId The ID of the proposal being voted on
    event Climeta__Vote(uint256 _votingNFT, uint256 _proposalId);

    /// @notice Emitted when a new proposal is added
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the new proposal
    event Climeta__NewProposal(address _benefactor, uint256 _proposalId);

    /// @notice Emitted when a proposal is changed
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the proposal being changed
    event Climeta__ChangeProposal(address _benefactor, uint256 _proposalId);

    /// @notice Emitted when a proposal is included in a voting round
    /// @param _votingRound The voting round in which the proposal was included
    /// @param _proposalId The ID of the proposal being included
    event Climeta__ProposalIncluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a proposal is excluded from a voting round
    /// @param _votingRound The voting round from which the proposal was excluded
    /// @param _proposalId The ID of the proposal being excluded
    event Climeta__ProposalExcluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a new beneficiary is added
    /// @param _beneficiary The address of the new beneficiary
    /// @param name The name of the new beneficiary
    event Climeta__NewBeneficiary(address _beneficiary, string name);

    /// @notice Emitted when a beneficiary is removed
    /// @param _beneficiary The address of the beneficiary being removed
    event Climeta__RemovedBeneficiary(address _beneficiary);

    /// @notice Emitted when a token is approved for use as treasury token
    /// @param _token The address of the ERC20 token added
    event Climeta__TokenApproved(address _token);

    /// @notice Emitted when a token is revoked for use as treasury token
    /// @param _token The address of the ERC20 token removed
    event Climeta__TokenRevoked(address _token);

    // Errors
    error Climeta__CannotRemoveLastAdmin();
    error Climeta__NotAdmin();
    error Climeta__NotRayWallet();
    error Climeta__NotAMember();
    error Climeta__NotApproved();
    error Climeta__NoProposal();
    error Climeta__AlreadyInRound();
    error Climeta__ProposalNotInRound();
    error Climeta__AlreadyVoted();
    error Climeta__NoVotes();
    error Climeta__NotFromAuthContract();
    error Climeta__NoFundsToWithdraw();
    error Climeta__ProposalHasVotes();
    error Climeta__ValueStillInContract();

    function votingFacetVersion() external pure returns (string memory);
    function setVotingRoundReward(uint256 _rewardAmount) external;
    function getVotingRoundReward() external returns (uint256);
    function addAllowedToken(address _token) external;
    function removeAllowedToken(address _token) external;
}