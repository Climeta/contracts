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
        bytes var2;
        mapping (address => uint) var3;
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
