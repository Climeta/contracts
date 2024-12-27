// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {DelMundoWallet} from "../DelMundoWallet.sol";

/*
 * @dev Extension of ERC-1155 that adds tracking of total supply per id.
 *
 *  This contract is the ERC1155 contract that stores the traits. These are the DelMundo swappable traits.
 *  We are hardcoding the max-supply of each so when configured, there cannot ever be more minted that what was configured and all are minted at once
 *  We are also creating individual uris for each trait. This allows us to add ipfs based metadata for every trait and add them at later dates too
 *  Traits cannot be transferred if the DelMundo is wearing them. This is implemented via the _update function and via an external
 *    Chainlink call to an API
 */
contract DelMundoTrait is ERC1155Supply, Ownable {
    error DelMundoTraits__AlreadyMinted();
    error DelMundoTraits__NullAddressError();
    error DelMundoTraits__TokenNotConfigured();
    error DelMundoTraits__TraitInUse();

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

    function _update(address from, address to, uint256[] memory ids, uint256[] memory values) internal override {
        // Restrict transfers if DelMundo is wearing the trait
        try DelMundoWallet(payable(from)).iAmADelMundoWallet() {
            (uint256 tokenId,,) = DelMundoWallet(payable(from)).token();

            // Loop through all transfers and determine if the DelMundo is wearing it and disallow transfer of the last item
            for (uint256 i = 0; i < ids.length; i++) {
                // Checking = rather than <= as < needs to result in a different error (ie don't have that amount to transfer anyway)
                if (isDelMundoWearing(tokenId, ids[i]) && (balanceOf(from, ids[i]) == values[i])  ) {
                    revert DelMundoTraits__TraitInUse();
                }
            }
            super._update(from, to, ids, values);
        } catch {
            super._update(from, to, ids, values);
        }
    }

    function isDelMundoWearing(uint256 tokenId, uint256 traitId) internal view returns (bool) {
        return true;
    }

}