// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {TraitSaleStorage} from "../storage/TraitSaleStorage.sol";
import { LibDiamond } from "../lib/LibDiamond.sol";
import { ITraitSale } from "../interfaces/ITraitSale.sol";

contract TraitSaleFacet is ERC1155Holder, ITraitSale  {
    ClimetaStorage internal s;

    constructor() {
    }

    function traitSaleFacetVersion() external pure returns(string memory) {
        return "1.0";
    }

    function setTokenPrice(uint256 tokenId, uint256 price) external {
        LibDiamond.enforceIsContractOwner();
        TraitSaleStorage.TraitSaleStruct storage ts = TraitSaleStorage.traitSaleStorage();

        ts.tokenPrices[tokenId] = price;
        emit TokenPriceSet(tokenId, price);
    }

    function buyTrait(uint256 tokenId) external {
        TraitSaleStorage.TraitSaleStruct storage ts = TraitSaleStorage.traitSaleStorage();

        uint256 price = ts.tokenPrices[tokenId];
        require(price > 0, "Token not for sale");

        if ( IERC1155(s.delMundoTraitAddress).balanceOf(address(this), tokenId) == 0 ) {
            revert DelMundoTraitSale__InsufficientBalance();
        }

        require( IERC20(s.raywardAddress).transferFrom(msg.sender, s.opsTreasuryAddress, price), "Payment failed");

        IERC1155(s.delMundoTraitAddress).safeTransferFrom(address(this), msg.sender, tokenId, 1, "");

        emit TokenSold(msg.sender, tokenId, 1, price);
    }

    function withdrawERC1155Tokens(address to, uint256 tokenId, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        IERC1155(s.delMundoTraitAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
    }
}