// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./interfaces/IRayWallet.sol";

import "./lib/MinimalReceiver.sol";
import "./lib/ERC6551AccountLib.sol";
import "./interfaces/IDelMundoWallet.sol";

contract WardrobeAccount is IERC165, IERC1271, IRayWallet, IERC721Receiver, IDelMundoWallet {
    uint256 public nonce;

    function iAmADelMundoWallet() external pure returns (bool) {
        return true;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
    external
    override
    returns(bytes4)
    {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

    // This function is to allow full use of this contract as a wallet. You can push whatever request you want to do
    // whatever you want with this, given that you are the owner. It is the owners wallet and they are responsible
    function executeCall(
        address to,
        uint256 value,
        bytes calldata data
    ) external payable returns (bytes memory result) {
        require(msg.sender == owner(), "Not token owner");

        ++nonce;

        emit TransactionExecuted(to, value, data);

        bool success;
        (success, result) = to.call{value: value}(data);

        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    function token()
    external
    view
    returns (
        uint256,
        address,
        uint256
    )
    {
        return ERC6551AccountLib.token();
    }

    function owner() public view returns (address) {
        (uint256 chainId, address tokenContract, uint256 tokenId) = this.token();
        if (chainId != block.chainid) return address(0);

        return IERC721(tokenContract).ownerOf(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return (interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IRayWallet).interfaceId ||
            interfaceId == type(IDelMundoWallet).interfaceId);
    }

    function isValidSignature(bytes32 hash, bytes memory signature)
    external
    view
    returns (bytes4 magicValue)
    {
        bool isValid = SignatureChecker.isValidSignatureNow(owner(), hash, signature);

        if (isValid) {
            return IERC1271.isValidSignature.selector;
        }

        return "";
    }
}