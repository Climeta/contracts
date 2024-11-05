// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ITraitSale {
    event TokenPriceSet(uint256 indexed tokenId, uint256 price);
    event TokenSold(address indexed buyer, uint256 indexed tokenId, uint256 amount, uint256 price);

    error DelMundoTraitSale__InsufficientBalance();

    function setTokenPrice(uint256 tokenId, uint256 price) external;
    function buyTrait(uint256 tokenId) external;
    function withdrawERC1155Tokens(address to, uint256 tokenId, uint256 amount) external;
    function traitSaleFacetVersion() external pure returns(string memory);
}