// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {TraitSaleStorage} from "../storage/TraitSaleStorage.sol";

contract DelMundoTraitSale is ERC1155Holder, Ownable {
    ClimetaStorage internal s;

    IERC20 public raywardToken;
    ERC1155 public delMundoTraits;

    event TokenPriceSet(uint256 indexed tokenId, uint256 price);
    event TokenSold(address indexed buyer, uint256 indexed tokenId, uint256 amount, uint256 price);

    error DelMundoTraitSale__InsufficientBalance();

    constructor() {
    }

    function setTokenPrice(uint256 tokenId, uint256 price) external onlyOwner {
        TraitSaleStorage.TraitSaleStruct storage ts = TraitSaleStorage.traitSaleStorage();

        ts.tokenPrices[tokenId] = price;
        emit TokenPriceSet(tokenId, price);
    }

    function buyTrait(uint256 tokenId, uint256 amount) external {
        TraitSaleStorage storage ts = TraitSaleStorage.;

        uint256 price = ts.tokenPrices[tokenId];
        require(price > 0, "Token not for sale");

        if (IERC1155(s.delMundoTraitAddress).balanceOf(address(this) < amount)) {
            revert DelMundoTraitSale__InsufficientBalance();
        }

        uint256 totalPrice = price * amount;
        require( IERC20(s.raywardAddress).transferFrom(msg.sender, address(this), totalPrice), "Payment failed");

        IERC1155(s.delMundoTraitAddress).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");

        emit TokenSold(msg.sender, tokenId, amount, totalPrice);
    }

    function withdrawERC1155Tokens(address to, uint256 tokenId, uint256 amount) external onlyOwner {
        IERC1155(s.delMundoTraitAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
    }
}