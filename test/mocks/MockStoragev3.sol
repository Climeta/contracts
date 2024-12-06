// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library MockStorage {
    struct MockStruct {
        // Collection address, tokenId, sold?
        mapping(uint256 => uint256) mapping1;
        mapping(uint256 => uint256) mapping2;
        mapping(uint256 => uint256) mapping3;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.mock")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.mock
    bytes32 constant MOCKSTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.mock")) - 1)) & ~bytes32(uint256(0xff));

    function mockStorage()
    internal
    pure
    returns (MockStruct storage mockstruct)
    {
        bytes32 position = MOCKSTRUCT_POSITION;
        assembly {
            mockstruct.slot := position
        }
    }
}
