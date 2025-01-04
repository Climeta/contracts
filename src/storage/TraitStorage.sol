// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library TraitStorage {

    struct TraitStruct {
        // Array of traits worn by every DelMundo
        mapping(uint256 => uint256[]) delMundoTraits;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.traits")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.traits
    bytes32 constant TRAITSTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.traits")) - 1)) & ~bytes32(uint256(0xff));

    function traitStorage()
    internal
    pure
    returns (TraitStruct storage traitstruct)
    {
        bytes32 position = TRAITSTRUCT_POSITION;
        assembly {
            traitstruct.slot := position
        }
    }
}
