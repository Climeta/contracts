// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

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
    function getAllowedTokens() external returns(address[] memory);
    function getDelMundoAddress() external returns(address);
    function getDelMundoTraitAddress() external returns(address);
    function getDelMundoWalletAddress() external returns(address);
    function getOpsTreasuryAddress() external returns(address);
    function getRaycognitionAddress() external returns(address);
    function getRayWalletAddress() external returns(address);
    function getRaywardAddress() external returns(address);
    function getRegistryAddress() external returns(address);
    function getVoteRaycognition() external returns (uint256);
    function getVoteReward() external returns (uint256);
    function getVotingRoundReward() external returns (uint256);
    function removeAllowedToken(address _token) external;
    function setVoteRaycognition(uint256) external;
    function setVoteReward(uint256 _rewardAmount) external;
    function setVotingRoundReward(uint256) external;
    function setWithdrawalType(bool) external;
    function updateOpsTreasuryAddress(address payable _ops) external;
}