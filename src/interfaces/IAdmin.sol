// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

/// @title IAdmin Climeta Admin Facet Standard
///  Note: the ERC-165 identifier for this interface is 0xdc5d3022
interface IAdmin {
    event Climeta__RewardWithdrawalTypeChange(bool value);
    event Climeta__TokenApproved(address _token);
    event Climeta__TokenRevoked(address _token);
    error Climeta__ValueStillInContract();
    event Climeta__VoteRaycognitionChanged(uint256 amount);
    event Climeta__VoteRewardChanged(uint256 amount);
    event Climeta__VotingRewardChanged(uint256 amount);

    function addAllowedToken(address _token) external;
    function adminFacetVersion() external pure returns (string memory);
    function getAllowedTokens() external view returns(address[] memory);
    function getDelMundoAddress() external view returns(address);
    function getDelMundoTraitAddress() external view returns(address);
    function getDelMundoWalletAddress() external view returns(address);
    function getOpsTreasuryAddress() external view returns(address);
    function getRaycognitionAddress() external view returns(address);
    function getRayWalletAddress() external view returns(address);
    function getRaywardAddress() external view returns(address);
    function getRegistryAddress() external view returns(address);
    function getVoteRaycognition() external view returns (uint256);
    function getVoteReward() external view returns (uint256);
    function getVotingRoundReward() external view returns (uint256);
    function removeAllowedToken(address _token) external;
    function setVoteRaycognition(uint256 _rewardAmount) external;
    function setVoteReward(uint256 _rewardAmount) external;
    function setVotingRoundReward(uint256 _rewardAmount) external;
    function setWithdrawalOnly(bool _withdrawRewardOnly) external;
    function updateOpsTreasuryAddress(address payable _ops) external;
}