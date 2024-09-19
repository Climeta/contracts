// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library DonationStorage {

    struct Donation {
        address benefactor;
        uint256 amount;
    }

    /// @custom:storage-location erc7201:io.climeta.donation
    struct DonationStruct {
        uint256 minimumDonation;
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
    bytes32 constant DONATIONSTRUCT_POSITION = 0xec92ca54fc291844a0adb1987da39eaa3844f24476cfb6d71afb4622e33a0300;

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
