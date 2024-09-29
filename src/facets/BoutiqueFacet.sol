// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {BoutiqueStorage} from "../storage/BoutiqueStorage.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract BoutiqueFacet {
    ClimetaStorage internal s;

    constructor(){
    }

    uint256 constant ERC721 = 721;
    uint256 constant ERC1155 = 1155;

    function addCollection(address _collection) external {
        LibDiamond.enforceIsContractOwner();
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        bs.collections.push(_address);
    }

    function removeCollection(address _collection) external {
        LibDiamond.enforceIsContractOwner();
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        // TODO remove from array code
        //bs.collections.pop();
    }

    function addERC721Item(address _collection, uint256 _tokenId, uint256 _priceRaywards, uint256 _priceEth) external {
        LibDiamond.enforceIsContractOwner();
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        bs.itemPriceRaywayrds[_collection][_tokenId] = _priceRaywards;
        bs.itemPriceEth[_collection][_tokenId] = _priceEth;
        IERC721(_collection).safeTransferFrom(msg.sender, address(this), _tokenId, "");
    }

    function addERC1155Item(address _collection, uint256 _tokenId, uint256 _amount, uint256 _priceRaywards, uint256 _priceEth) external {
        LibDiamond.enforceIsContractOwner();
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        bs.itemPriceRaywayrds[_collection][_tokenId] = _priceRaywards;
        bs.itemPriceEth[_collection][_tokenId] = _priceEth;
        IERC1155(_collection).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
    }

    function removeERC721Item(address _collection, uint256 _tokenId) external {
        LibDiamond.enforceIsContractOwner();
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        bs.itemPriceRaywayrds[_collection][_tokenId] = 0;
        bs.itemPriceEth[_collection][_tokenId] = 0;
        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, "");
    }

    function removeERC1155Item(address _collection, uint256 _tokenId, uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        bs.itemPriceRaywayrds[_collection][_tokenId] = 0;
        bs.itemPriceEth[_collection][_tokenId] = 0;
        IERC1155(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, _amount, "");
    }

    function buyERC721Item(address _collection, uint256 _tokenId) external payable {
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        uint256 priceInRaywards = bs.itemPriceRaywayrds[_collection][_tokenId];
        uint256 priceInEth = bs.itemPriceEth[_collection][_tokenId];

        require(erc721Items[_collection][_tokenId] == false, "Sold");

        if (priceInEth > msg.value) {
            revert();
        }
        require( IERC20(s.raywardAddress).transferFrom(msg.sender, s.opsTreasuryAddress, priceInRaywards), "Payment failed");

        erc721Items[_collection][_tokenId] = true;

        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, "");
    }


    function buyERC721Item(address _collection, uint256 _tokenId) external payable {
        BoutiqueStruct bs = BoutiqueStorage.boutiqueStorage();
        uint256 priceInRaywards = bs.itemPriceRaywayrds[_collection][_tokenId];
        uint256 priceInEth = bs.itemPriceEth[_collection][_tokenId];

        require(erc1155Items[_collection][_tokenId] == false, "Sold");

        if (priceInEth > msg.value) {
            revert();
        }
        require( IERC20(s.raywardAddress).transferFrom(msg.sender, s.opsTreasuryAddress, priceInRaywards), "Payment failed");

        IERC721(_collection).safeTransferFrom(address(this), msg.sender, _tokenId, "");
    }


}
