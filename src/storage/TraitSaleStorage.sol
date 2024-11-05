// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library TraitSaleStorage {

    struct TraitSaleStruct {
        mapping(uint256 => uint256) tokenPrices;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.traitsale")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.traitsale
    bytes32 constant TRAITSALESTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.traitsale")) - 1)) & ~bytes32(uint256(0xff));

    function traitSaleStorage()
    internal
    pure
    returns (TraitSaleStruct storage traitsalestruct)
    {
        bytes32 position = TRAITSALESTRUCT_POSITION;
        assembly {
            traitsalestruct.slot := position
        }
    }
}
