// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library TraitSaleStorage {
    /// @custom:storage-location erc7201:io.climeta.traitsale
    struct TraitSaleStruct {
        mapping(uint256 => uint256) public tokenPrices;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.traitsale")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant TRAITSALESTRUCT_POSITION = 0x026ffe04db9521375030ee99fdf75c49adc62dac82dac9082eecb8a607037600;

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
