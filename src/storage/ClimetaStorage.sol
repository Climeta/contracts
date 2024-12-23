// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

struct ClimetaStorage {
    address climetaAddress;
    address delMundoAddress;
    address delMundoWalletAddress;
    address delMundoTraitAddress;
    address rayWalletAddress;
    address raywardAddress;
    address raycognitionAddress;
    address opsTreasuryAddress;
    address registryAddress;
    address treasuryStablecoin;

    // Uniswap v4 addresses
    address liquidityPoolAddress;
    address uniswapRouter;
    uint24 uniswapPoolFee;
    uint48 approvalExpirationTime;

    // Raycognisiton
    uint256 voteRaycognitionAmount;
    address[] allowedTokens;
    uint256 votingRoundReward;
    uint256 voteReward;
    bool withdrawRewardsOnly;

    // for each charity address, store all the amounts available  to withdraw
    mapping(address => mapping(address => uint256)) erc20Withdrawls;
    // for each Token, store all the individual donations
    mapping(address => mapping(address => uint256)) erc20Donations;
    mapping(address => uint256) tokenBalances;
    // ETH send to projects
    uint256 totalETHToProjects;
    // list of charity addresses and their ETH balances
    mapping(address => uint256) totalTokenToProjects;

}
