// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

struct ClimetaStorage {
    address climetaAddress;
    address delMundoAddress;
    address rayWalletAddress;
    address raywardAddress;
    address rayputationAddress;
    address opsTreasuryAddress;
    address registryAddress;
    uint256 everyoneVoteReward;
    uint256 votingRound;
    // for each charity address, store all the amounts available  to withdraw
    mapping(address => mapping(address => uint256)) erc20Withdrawls;
    // for each Token, store all the individual donations
    mapping(address => mapping(address => uint256)) erc20Donations;
    // donations of ETH from donators
    mapping(address => uint256) ethDonations;
    // list of charity addresses and their ETH balances
    mapping(address => uint256) ethWithdrawls;
    // ERC20 tokens approved for use within Climeta
    mapping(address => bool) whitelistedTokens;
    // List of token balances for each token
    mapping(address => uint256) tokenBalances;
}
