// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library MarketplaceStorage {
    struct MarketplaceStruct {
        uint var1;
        bytes var2;
        mapping (address => uint) var3;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.marketplace")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.marketplace
    bytes32 constant MARKETPLACESTRUCT_POSITION = 0x15654f1b319f13eff871c556199799b191f8eb75f3c033445da3bf58532cf900;

    function marketplaceStorage()
    internal
    pure
    returns (MarketplaceStruct storage marketplacestruct)
    {
        bytes32 position = MARKETPLACESTRUCT_POSITION;
        assembly {
            marketplacestruct.slot := position
        }
    }
}
