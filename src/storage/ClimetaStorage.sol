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

    // Charities + Brands
    // Mapping to hold the beneficiary address and the data -
    // TODO do we map charity by an id or by an address?
    // do we just use addresses and map those in database?
    // the proposal will be an id and metadata and a charity address for withdrawal...
    // Need an id, metadata and a possible list of addresses with a currentAddress
    //mapping(address => Beneficiary) beneficiaries;


}
