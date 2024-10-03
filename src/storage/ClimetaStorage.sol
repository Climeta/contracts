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

    // Charities + Brands
    // Mapping to hold the beneficiary address and the data -
    // TODO do we map charity by an id or by an address?
    // do we just use addresses and map those in database?
    // the proposal will be an id and metadata and a charity address for withdrawal...
    // Need an id, metadata and a possible list of addresses with a currentAddress
    //mapping(address => Beneficiary) beneficiaries;


}
