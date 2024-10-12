// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library BoutiqueStorage {
    struct BoutiqueStruct {
        // Collection address, tokenId, sold?
        mapping(address => mapping(uint256 => bool)) erc721Items;
        // Collection address, tokenId, amount_remaining
        mapping(address => mapping(uint256 => uint256)) erc1155Items;

        // Collection address, tokenId, price
        mapping(address => mapping(uint256 => uint256)) itemPriceRaywayrds;
        mapping(address => mapping(uint256 => uint256)) itemPriceEth;
        address[] collections;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.boutique")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.boutique
    bytes32 constant BOUTIQUESTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.boutique")) - 1)) & ~bytes32(uint256(0xff));

    function boutiqueStorage()
    internal
    pure
    returns (BoutiqueStruct storage boutiquestruct)
    {
        bytes32 position = BOUTIQUESTRUCT_POSITION;
        assembly {
            boutiquestruct.slot := position
        }
    }
}
