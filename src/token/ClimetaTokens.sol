// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClimetaTokens is ERC1155, ERC1155URIStorage,  Ownable {
    mapping(uint256 => address[]) public minters;
    mapping(uint256 => bool) public releasedTokens;
    mapping(uint256 => mapping (address => bool)) public hasMinted;
    mapping(uint256 => string) public metadata;

    error ClimetaTokens__AlreadyMinted();
    error ClimetaTokens__NotCreatedYet();

    constructor(address initialOwner, string memory _uri) ERC1155(_uri) Ownable(initialOwner) {}

    function mint(uint256 _id, address _address)
    external
    {
        if (!releasedTokens[_id]) {
            revert ClimetaTokens__NotCreatedYet();
        }

        if (hasMinted[_id][_address]) {
            revert ClimetaTokens__AlreadyMinted();
        }

        minters[_id].push(_address);
        hasMinted[_id][_address] = true;
        _mint(_address, _id, 1, "");
    }

    function updateURI(uint256 _id, string memory _newuri) external onlyOwner {
        metadata[_id] = _newuri;
        releasedTokens[_id] = true;
    }

    function uri(uint256 _id) external view override (ERC1155URIStorage, ERC1155) returns (string memory) {
        return metadata[_id];
    }
}