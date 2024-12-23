// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library MarketplaceStorage {
    struct MarketplaceStruct {
        // Collection address, tokenId, available?
        mapping(address => mapping(uint256 => bool)) erc721Items;
        // Collection address, tokenId, amount_remaining
        mapping(address => mapping(uint256 => uint256)) erc1155Items;

        // Collection address, tokenId, creator
        mapping(address => mapping(uint256 => address)) itemCreator;
        // Collection address, tokenId, Creator Royalty
        mapping(address => mapping(uint256 => uint256)) itemRoyalties;


        // Collection address, tokenId, price
        mapping(address => mapping(uint256 => uint256)) itemPriceRaywards;
        mapping(address => mapping(uint256 => uint256)) itemPriceEth;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.marketplace")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.marketplace
    bytes32 constant MARKETPLACESTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.marketplace")) - 1)) & ~bytes32(uint256(0xff));

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
