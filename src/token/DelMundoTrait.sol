// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @dev Extension of ERC-1155 that adds tracking of total supply per id.
 *
 *  This contract is the ERC1155 contract that stores the traits. These are the DelMundo swappable traits.
 *  We are hardcoding the max-supply of each so when configured, there cannot ever be more minted that what was configured and all are minted at once
 *  We are also creating individual uris for each trait. This allows us to add ipfs based metadata for every trait and add them at later dates too,
 */

// TODO need to create all the erc1155 metadata for every trait. This needs to contain the number of each trait that can be minted.

contract DelMundoTrait is ERC1155Supply, Ownable {
    error DelMundoTraits__AlreadyMinted();
    error DelMundoTraits__NullAddressError();
    error DelMundoTraits__TokenNotConfigured();

    struct TraitStruct {
        string uri;
        uint256 maxSupply;
    }

    mapping(uint256 => TraitStruct) private tokenURIs;

    constructor(address initialOwner) ERC1155("DelMundoTraits") Ownable(initialOwner) {}

    function uri(uint256 tokenId) public view override returns (string memory) {
        return tokenURIs[tokenId].uri;
        }

    function maxSupply(uint256 tokenId) public view returns (uint256) {
        return tokenURIs[tokenId].maxSupply;
    }

    function setURI(uint256 tokenId, string memory newuri, uint256 supply) public onlyOwner {
        if (exists(tokenId)) {
            revert DelMundoTraits__AlreadyMinted();
        }
        tokenURIs[tokenId] = TraitStruct(newuri, supply);
    }

    function mint(address account, uint256 id, bytes memory data)
    public
    onlyOwner
    {
        // Ensure no more can be minted once we have minted.
        if (totalSupply(id) > 0) {
            revert DelMundoTraits__AlreadyMinted();
        }
        if (tokenURIs[id].maxSupply == 0) {
            revert DelMundoTraits__TokenNotConfigured();
        }
        _mint(account, id, tokenURIs[id].maxSupply, data);
    }
}