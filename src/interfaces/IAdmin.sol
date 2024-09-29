// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IAdmin {
    event Climeta__TokenApproved(address _token);
    event Climeta__VotingRewardChanged(uint256 amount);
    event Climeta__TokenRevoked(address _token);

    error Climeta__ValueStillInContract();

    function adminFacetVersion() external pure returns (string memory);
    function setVotingRoundReward(uint256 _rewardAmount) external;
    function getVotingRoundReward() external returns (uint256);
    function updateOpsTreasuryAddress(address payable _ops) external;
    function addAllowedToken(address _token) external;
    function removeAllowedToken(address _token) external;
    function getOpsTreasuryAddress() external returns(address);
    function getDelMundoAddress() external returns(address);
    function getDelMundoTraitAddress() external returns(address);
    function getRaywardAddress() external returns(address);
    function getRayputationAddress() external returns(address);
    function getRegistryAddress() external returns(address);
}