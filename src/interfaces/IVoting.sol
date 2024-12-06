// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/// @title IVoting Climeta Voting Facet Standard
///  Note: the ERC-165 identifier for this interface is 0xa9092a14
interface IVoting {

    /// @notice Emitted when a beneficiary's status is updated
    /// @param _beneficiary The address of the new beneficiary
    /// @param _approved flag showing if the address is an approved beneficiary or not
    event Climeta__BeneficiaryApproval(address _beneficiary, bool _approved);

    /// @notice Emitted when an ERC20 payout is made
    /// @param _to The address receiving the payout
    /// @param _token The address of the ERC20 being paid out
    /// @param _amount The amount of the payout
    event Climeta__ERC20Payout(address _to, address _token, uint256 _amount);

    /// @notice Emitted when a new proposal is added
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the new proposal
    event Climeta__NewProposal(address _benefactor, uint256 _proposalId);

    /// @notice Emitted when a payout is made
    /// @param _to The address receiving the payout
    /// @param _amount The amount of the payout
    event Climeta__Payout(address _to, uint256 _amount);

    /// @notice Emitted when a proposal is changed
    /// @param _proposalId The ID of the proposal being changed
    /// @param _proposalURI The new uri for the metadata
    event Climeta__ProposalChanged(uint256 _proposalId, string _proposalURI);

    /// @notice Emitted when a proposal is excluded from a voting round
    /// @param _votingRound The voting round from which the proposal was excluded
    /// @param _proposalId The ID of the proposal being excluded
    event Climeta__ProposalExcluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a proposal is included in a voting round
    /// @param _votingRound The voting round in which the proposal was included
    /// @param _proposalId The ID of the proposal being included
    event Climeta__ProposalIncluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a reward is given out
    /// @param _delmundoId The DelMundo being awarded
    /// @param _amount The amount of the reward
    event Climeta__RaycognitionGranted(uint256 _delmundoId, uint256 _amount);

    /// @notice Emitted when an ERC20 payout is made
    /// @param _claimer The address withdrawing
    /// @param _amount The amount of the withdrawal
    event Climeta__RaywardClaimed(address _claimer, uint256 _amount);

    /// @notice Emitted when a token is approved for use as treasury token
    /// @param _token The address of the ERC20 token added
    event Climeta__TokenApproved(address _token);

    /// @notice Emitted when a token is revoked for use as treasury token
    /// @param _token The address of the ERC20 token removed
    event Climeta__TokenRevoked(address _token);

    /// @notice Emitted when a vote is cast
    /// @param _votingNFT The NFT used to vote
    /// @param _proposalId The ID of the proposal being voted on
    event Climeta__Vote(uint256 _votingNFT, uint256 _proposalId);

    /// @notice Emitted when a voting round is successfully ended by Climeta and we move to next round
    /// @param _votingRound The voting round that has ended.
    event Climeta__VotingRoundEnded(uint256 _votingRound);

    // Errors
    error Climeta__AlreadyInRound();
    error Climeta__AlreadyVoted();
    error Climeta__NoFundsToWithdraw();
    error Climeta__NoProposal();
    error Climeta__NotAMember();
    error Climeta__NotApproved();
    error Climeta__NotProposalOwner();
    error Climeta__NotRayWallet();
    error Climeta__NoVotes();
    error Climeta__ProposalHasVotes();
    error Climeta__ProposalNotInRound();
    error Climeta__RaywardConfigError();

    function addProposal(string calldata _proposalURI) external returns(uint256);
    function addProposalByOwner(address _beneficiary, string calldata _proposalURI) external returns(uint256);
    function addProposalToVotingRound (uint256 _proposalId) external;
    function approveBeneficiary(address _beneficiary, bool _approved) external;
    function castVote(uint256 _propId) external;
    function endVotingRound () external payable;
    function getProposal(uint256 _proposalId) external view returns(address, string memory);
    function getProposals(uint256 _round) external returns(uint256[] memory);
    function getTokenAmountForRound(address _token) external view returns(uint256);
    function getVotes(uint256 _proposalId) external returns(uint256[] memory);
    function getVotingRound() external view returns(uint256);
    function getWithdrawAmount(address _beneficiary, address _token) external view returns(uint256);
    function grantRaycognition (uint256 _delmundoId, uint256 _amount) external;
    function hasVoted(uint256 _tokenId) external view returns(bool);
    function isBeneficiary(address _beneficiary) external view returns(bool);
    function pushPayment(address _beneficiary) external;
    function removeProposalFromVotingRound (uint256 _proposalId) external;
    function sendRaywards(address _to, uint256 _amount) external;
    function updateProposalMetadata(uint256 _propId, string calldata _proposalURI) external;
    function votingFacetVersion() external pure returns (string memory);
    function withdraw() external;
    function withdrawRaywards() external;
}