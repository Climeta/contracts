// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// Import ERC721 contract from openzepellin lib
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Declaring the contract
contract TestNFT is ERC721 {

    // Defining a counter for token IDs
    uint256 public tokenId;

    constructor() ERC721("Exclusive", "EXC") {}

    // Function to mint a new NFT
    function mintNFT(address recipient, string memory tokenURI) public  {
        _safeMint(recipient, tokenId);
        tokenId++;
    }
}
