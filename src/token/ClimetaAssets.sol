// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {ERC1155Supply} from "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @dev Extension of ERC-1155 that adds tracking of total supply per id.
 *
 *  This contract is the ERC1155 contract that stores ClimetaAssets that can be sold in the marketplace.
 *  We are hardcoding the max-supply of each so when configured, there cannot ever be more minted that what was configured and all are minted at once
 *  We are also creating individual uris for each trait. This allows us to add ipfs based metadata for every NFT and add them at later dates too
 */
contract ClimetaAssets is ERC1155Supply, Ownable {
    error ClimetaAssets__AlreadyMinted();
    error ClimetaAssets__TokenNotConfigured();

    struct AssetStruct {
        string uri;
        address creator;
        uint256 maxSupply;
    }

    mapping(uint256 => AssetStruct) private tokenURIs;

    constructor(address initialOwner) ERC1155("ClimetaAssets") Ownable(initialOwner) {}

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId].uri;
    }

    function maxSupply(uint256 tokenId) public view returns (uint256) {
        return tokenURIs[tokenId].maxSupply;
    }

    function setMetadata(uint256 tokenId, address creator, string memory newuri, uint256 supply) public onlyOwner {
        if (exists(tokenId)) {
            revert ClimetaAssets__AlreadyMinted();
        }
        tokenURIs[tokenId] = AssetStruct(newuri, creator, supply);
    }

    function mint(address account, uint256 id, bytes memory data)
    public
    onlyOwner
    {
        // Ensure no more can be minted once we have minted.
        if (totalSupply(id) > 0) {
            revert ClimetaAssets__AlreadyMinted();
        }
        if (tokenURIs[id].maxSupply == 0) {
            revert ClimetaAssets__TokenNotConfigured();
        }
        _mint(account, id, tokenURIs[id].maxSupply, data);
    }
}