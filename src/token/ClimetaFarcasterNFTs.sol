// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClimetaFarcasterNFTs is ERC1155, ERC1155URIStorage,  Ownable {
    mapping(uint256 => uint256[]) public minters;
    mapping(uint256 => bool) public releasedTokens;
    mapping(uint256 => mapping (uint256 => bool)) public hasMinted;
    mapping(uint256 => string) public metadata;

    error ClimetaFarcasterNFTs__AlreadyMinted();
    error ClimetaFarcasterNFTs__NotCreatedYet();

    constructor(address initialOwner, string memory _uri) ERC1155(_uri) Ownable(initialOwner) {}

    function mint(uint256 fid, uint256 id)
    public
    {
        if (!releasedTokens[id]) {
            revert ClimetaFarcasterNFTs__NotCreatedYet();
        }

        if (hasMinted[id][fid]) {
            revert ClimetaFarcasterNFTs__AlreadyMinted();
        }

        minters[id].push(fid);
        hasMinted[id][fid] = true;
        _mint(msg.sender, id, 1, "");
    }

    function updateURI(uint256 id, string memory newuri) public onlyOwner {
        metadata[id] = newuri;
        releasedTokens[id] = true;
    }

    function uri(uint256 id) public view override (ERC1155URIStorage, ERC1155)returns (string memory) {
        return metadata[id];
    }
}