// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

struct ClimetaStorage {
    address climetaAddress;
    address delMundoAddress;
    address delMundoTraitAddress;
    address rayWalletAddress;
    address raywardAddress;
    address rayputationAddress;
    address opsTreasuryAddress;
    address registryAddress;
    uint256 everyoneVoteReward;
    // TODO how do we handle constants in a diamond? Consts file?
    uint256 CLIMETA_PERCENTAGE;
    // for each charity address, store all the amounts available  to withdraw
    mapping(address => mapping(address => uint256)) erc20Withdrawls;
    // for each Token, store all the individual donations
    mapping(address => mapping(address => uint256)) erc20Donations;
    // donations of ETH from donators
    mapping(address => uint256) ethDonations;
    // list of charity addresses and their ETH balances
    mapping(address => uint256) ethWithdrawls;
    // ERC20 tokens approved for use within Climeta
    address[] allowedTokens;
    // List of token balances for each token
    mapping(address => uint256) tokenBalances;
    // ETH send to projects
    uint256 totalETHToProjects;
    // list of charity addresses and their ETH balances
    mapping(address => uint256) totalTokenToProjects;
    uint256 votingRoundReward;

    // Charities + Brands
    // Mapping to hold the beneficiary address and the data -
    // TODO do we map charity by an id or by an address?
    // do we just use addresses and map those in database?
    // the proposal will be an id and metadata and a charity address for withdrawal...
    // Need an id, metadata and a possible list of addresses with a currentAddress
    //mapping(address => Beneficiary) beneficiaries;


}
