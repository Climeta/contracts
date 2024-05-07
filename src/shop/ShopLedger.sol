// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "../RayWallet.sol";

contract ShopLedger is Initializable, ERC721Holder, ERC1155Holder, AccessControlEnumerableUpgradeable {
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    uint256 public itemId;
    address public rayWalletAddress;
    address public raywardAddress;

    struct ShopItem {
        uint256 id;
        address tokenContract;
        uint256 tokenId;
        uint256 priceInBase;
        uint256 priceInRay;
        bool sold;
    }

    mapping(uint256 => ShopItem) public saleItemsById;
    ShopItem[] public saleItems;

    modifier onlyAdmin () {
        require (hasRole(CUSTODIAN_ROLE, msg.sender)  , "Not an admin");
        _;
    }

    function initialize (address _raywardAddress , address _rayWalletAddress ) public initializer {
        _grantRole(CUSTODIAN_ROLE, msg.sender);
        rayWalletAddress = _rayWalletAddress;
        raywardAddress = _raywardAddress;
        itemId = 0;
    }

    function getAllItems() external view returns (ShopItem[] memory) {
        return saleItems;
    }

    function getToken(uint256 id) external view returns (ShopItem memory) {
        return saleItemsById[id];
    }

    function addToken(address tokenContract, uint256 tokenId, uint256 priceInBase, uint256 priceInRay) external onlyAdmin returns (ShopItem memory) {
        itemId++;
        ShopItem memory newItem = ShopItem(itemId, tokenContract, tokenId, priceInBase, priceInRay, false);
        saleItems.push(newItem);
        saleItemsById[itemId] = newItem;
        return newItem;
    }

    function removeToken(address tokenContract, uint256 tokenId) external onlyAdmin {
        //TODO Not very efficient could have an collection array of item arrays
        delete saleItemsById[itemId];
        uint256 length = saleItems.length;
        for (uint256 i=0; i < length;i++) {
            if (saleItems[i].tokenId == tokenId && saleItems[i].tokenContract == tokenContract) {
                saleItems[i] = saleItems[length-1];
                saleItems.pop();
            }
        }
    }

    function isSold(uint256 id) external view returns(bool) {
        return saleItemsById[id].sold;
    }

    function buyTokenWithBoth(uint256 id, address delmundoWallet) payable public {
        require ( RayWallet(payable(delmundoWallet)).owner() == msg.sender, "Not the owner of the Del Mundo" );

        ShopItem storage _token = saleItemsById[id];
        require (_token.sold == false, "Already sold");
        require (msg.value >= _token.priceInBase, "Not enough crypto");

        // Check on the transfer of the Raywards. This must have been preapproved which shows the caller is in fact the owner of the wallet
        IERC20 raywardContract = IERC20(raywardAddress);
        require (raywardContract.transferFrom(delmundoWallet, rayWalletAddress, _token.priceInRay ), "Raywards not transferred");
        IERC721 nftContract = IERC721(_token.tokenContract);
        _token.sold = true;
        nftContract.safeTransferFrom(address(this), msg.sender, id);
    }

    function buyTokenWithBase(uint256 id) payable public {
        ShopItem storage _token = saleItemsById[id];
        require (_token.sold == false, "Already sold");
        require (msg.value >= _token.priceInBase, "Not enough crypto");
        IERC721 nftContract = IERC721(_token.tokenContract);
        _token.sold = true;
        nftContract.safeTransferFrom(address(this), msg.sender, id);
    }

    function buyTokenWithRaywards(uint256 id) public {
        ShopItem memory _token = saleItemsById[id];
        require (_token.sold == false, "Already sold");
        IERC20 raywardContract = IERC20(raywardAddress);
        require (raywardContract.transferFrom(msg.sender, rayWalletAddress, _token.priceInRay ), "Raywards not transferred");
        IERC721 nftContract = IERC721(_token.tokenContract);
        _token.sold = true;
        nftContract.safeTransferFrom(address(this), msg.sender, id);
    }

    function version() external pure returns (string memory) {
        return "1.0";
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(AccessControlEnumerableUpgradeable, ERC1155Holder)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }


}
