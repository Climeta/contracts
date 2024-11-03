// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library DonationStorage {

    struct DonationStruct {
        uint256 minimumEthDonation;
        mapping(address => uint256) minimumERC20Donations;
        uint256 totalDonatedAmount;
        // Total donations for every token
        mapping (address => uint256) totalTokenDonations;
        // Donator and their total ETH donations
        mapping (address => uint256) donations;
        // Array of all ETH donators
        address[] donators;
        // Donator and their total ERC20 donations
        mapping (address => mapping (address => uint256)) erc20donations;
        // Array of all ERC20 donators
        address[] erc20donators;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.donation")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.donation
    bytes32 constant DONATIONSTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.donation")) - 1)) & ~bytes32(uint256(0xff));

    function donationStorage()
    internal
    pure
    returns (DonationStruct storage donationstruct)
    {
        bytes32 position = DONATIONSTRUCT_POSITION;
        assembly {
            donationstruct.slot := position
        }
    }
}
