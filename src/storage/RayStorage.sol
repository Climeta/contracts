// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

struct ShopItem {
    uint256 id;
    address tokenContract;
    uint256 tokenId;
    uint256 priceInBase;
    uint256 priceInRay;
    bool sold;
}


struct RayStorage {
    address rayWalletAddress;
    address raywardAddress;
    uint256 nextShopItemId;

}
