// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721Pausable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {IDelMundoWallet} from "../interfaces/IDelMundoWallet.sol";

/**
 * @title Membership NFT for Climeta
 * @author matt@climeta.io
 * @notice The DelMundo is an ERC721 NFT.
 * The metadata and images are stored on IPFS.
 * The metadata uris for each Del Mundo are completely distinct, there is no IPFS folder naming convention.
 * This is done because the images are pre-made and pre-loaded to IPFS and to preserve the anonymity of the next DelMundo
 * till mint time, the uri for the metadata should not be guessable.
 * We uses some extensions so minting can be paused
 * @dev bugbounty contact mysaviour@climeta.io
 */
contract DelMundo is  ERC721Enumerable, EIP712, ERC721URIStorage, ERC721Pausable, AccessControl, ERC721Royalty {

    event DelMundo__AdminAdded(address indexed newAdmin);
    event DelMundo__AdminRevoked(address indexed oldAdmin);
    event DelMundo__ContractURIUpdated(string uri);
    event DelMundo__MaxPerWalletUpdated(uint256 amount);
    event DelMundo__MaxSupplyUpdated(uint256 amount);
    event DelMundo__Minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);
    event DelMundo__MinterAdded(address indexed newMinter);
    event DelMundo__MinterRevoked(address indexed oldMinter);
    event DelMundo__RoyaltyUpdated(address indexed recipient, uint96 value);
    event DelMundo__Withdraw(address indexed recipient, uint256 value);
    event DelMundo__ResellEnabled();

    error DelMundo__AlreadyMinted();
    error DelMundo__CannotMoveToDelMundoWallet();
    error DelMundo__IncorrectSigner();
    error DelMundo__InsufficientFunds();
    error DelMundo__NotRay(address caller);
    error DelMundo__NullAddressError();
    error DelMundo__SoldOut();
    error DelMundo__TooMany();
    error DelMundo__CannotMoveYet();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

// Signing constants
    string public constant SIGNING_DOMAIN = "DelMundo-Voucher";
    string public constant SIGNING_VERSION = "1";
    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 public constant VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");

    // Some start constants to manage token distribution
    uint256 public s_maxPerWalletAmount = 5;
    uint256 public s_currentMaxSupply = 1000;
    bool canResell = false;
    // Mapping to flag minted tokens
    mapping (uint256 => bool) public s_isTokenMinted;

    // Del Mundo redeeming voucher. Contains the id, ipfs url, set price and the signature of a minter.
    struct NFTVoucher {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
        bytes signature;
    }

    constructor(address _admin)
    ERC721("DelMundo", "DEL-MUNDO")
    EIP712(SIGNING_DOMAIN, SIGNING_VERSION) {
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(ADMIN_ROLE, _admin);
    }

    modifier onlyRay () {
        if (!hasRole(ADMIN_ROLE, msg.sender)) {
            revert DelMundo__NotRay(msg.sender);
        }
        _;
    }

    //////////////// ADMIN FUNCTIONS ////////////////

    function addAdmin(address newAdmin) external onlyRay {
        emit DelMundo__AdminAdded(newAdmin);
        _grantRole(ADMIN_ROLE, newAdmin);
    }
    function revokeAdmin(address oldAdmin) external onlyRay {
        require (msg.sender != oldAdmin, "Can't revoke yourself");
        emit DelMundo__AdminRevoked(oldAdmin);
        _revokeRole(ADMIN_ROLE, oldAdmin);
    }
    function addMinter(address newMinter) external onlyRay {
        emit DelMundo__MinterAdded(newMinter);
        _grantRole(MINTER_ROLE, newMinter);
    }
    function revokeMinter(address oldMinter) external onlyRay {
        emit DelMundo__MinterRevoked(oldMinter);
        _revokeRole(MINTER_ROLE, oldMinter);
    }
    function pause() external onlyRay {
        _pause();
    }
    function unpause() external onlyRay {
        _unpause();
    }
    function updateMaxSupply(uint256 newAmount) external onlyRay {
        emit DelMundo__MaxSupplyUpdated(newAmount);
        s_currentMaxSupply = newAmount;
    }
    function updateMaxPerWalletAmount(uint256 newAmount) external onlyRay {
        emit DelMundo__MaxPerWalletUpdated(newAmount);
        s_maxPerWalletAmount = newAmount;
    }
    function setDefaultRoyalties(address recipient, uint96 value) external onlyRay {
        emit DelMundo__RoyaltyUpdated(recipient, value);
        _setDefaultRoyalty(recipient, value);
    }
    // ERC7572 metadata
    string private _contractURI;
    function setContractURI(string memory newURI) public onlyRay  {
        emit DelMundo__ContractURIUpdated(newURI);
        _contractURI = newURI;
    }
    function enableResell() external onlyRay {
        emit DelMundo__ResellEnabled();
        canResell = true;
    }


    //////////////// VIEW FUNCTIONS ////////////////

    /// @notice Returns all tokens owned by an address
    /// @param owner - address of the owner of the Ray tokens
    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 numberOfTokens = balanceOf(owner);
        uint256[] memory rays = new uint256[](numberOfTokens);

        for (uint i = 0; i < numberOfTokens; i++ ) {
            rays[i] = tokenOfOwnerByIndex(owner, i);
        }
        return rays;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }


    //////////////// ERC712 FUNCTIONS ////////////////

    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            VOUCHER_TYPEHASH,
            voucher.tokenId,
            keccak256(bytes(voucher.uri)),
            voucher.minPrice
        )));
    }

    /// @notice Verifies the signature for a given NFTVoucher, returning the address of the signer.
    /// @dev Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
    /// @param voucher An NFTVoucher describing an un-minted NFT.
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /** @dev This is the core minting function.
     * The voucher is a pre signed message containing the token id of the NFT to mint as well as the metadata uri location on IPFS
     * The prefixed price is also included and signed so nothing can be tampered with.
     *
     * Once minted, the voucher cannot be replayed as the tokenId will be already minted. We manage the token ids outside
     * NFTs and their ids outside the contract and provide randomised order vouchers to members.
     *
     * @param voucher NFTVoucher struct containing tokenId, ipfs metadata uri, price and the typed data signature.
     */
    function redeem(NFTVoucher calldata voucher) external payable  returns (uint256) {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        // make sure that the signer is authorized to mint NFTs
        if (!hasRole(MINTER_ROLE, signer)) {
            revert DelMundo__IncorrectSigner();
        }

        if (s_isTokenMinted[voucher.tokenId]) {
            revert DelMundo__AlreadyMinted();
        }

        // make sure that the redeemer is paying enough to cover the price
        if (msg.value < voucher.minPrice) {
            revert DelMundo__InsufficientFunds();
        }

        uint256 supply = totalSupply();
        if (supply > s_currentMaxSupply) {
            revert DelMundo__SoldOut();
        }

        uint256 totalOwned = tokensOfOwner(msg.sender).length;
        if (totalOwned >= s_maxPerWalletAmount) {
            revert DelMundo__TooMany();
        }

        s_isTokenMinted[voucher.tokenId] = true;
        // first assign the token to the signer, to establish provenance on-chain
        emit DelMundo__Minted(voucher.tokenId, voucher.uri, msg.sender);
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

        return voucher.tokenId;
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
    external onlyRay
    {
        if (s_isTokenMinted[tokenId]) {
            revert DelMundo__AlreadyMinted();
        }
        uint256 supply = totalSupply();
        if (supply > s_currentMaxSupply) {
            revert DelMundo__SoldOut();
        }
        s_isTokenMinted[tokenId] = true;
        emit DelMundo__Minted(tokenId, uri, to);
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // @dev this override prevents DelMundos from being moved to the ERC6551 locker wallet of another DelMundo and includes
    // a check to prevent DelMundos from being resold or transferred until the canResell flag is set to true, which is a one time event only (cannot be revoked).
    function _update (address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) returns(address) {
        if (!canResell) {
            address owner = _ownerOf(tokenId);
            // if the canresell hasn't been enabled, then only allow transfers from redeeming/minting processes, as these are part of the redeeming process itself.
            if ( !hasRole(MINTER_ROLE, owner) && owner != address(0)) {
                revert DelMundo__CannotMoveYet();
            }
        }
        bool isDelMundoWallet = ERC165Checker.supportsInterface(to, type(IDelMundoWallet).interfaceId);
        if (isDelMundoWallet) {
            revert DelMundo__CannotMoveToDelMundoWallet();
        }
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Royalty, ERC721Enumerable, AccessControl, ERC721URIStorage)
    returns (bool)
    {
        // TODO I shouldn't have to do this as I understand, but I do to make it work
        return
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC721Royalty).interfaceId ||
            interfaceId == type(ERC721Enumerable).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            interfaceId == type(ERC721URIStorage).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function withdraw(address payable account) external payable onlyRay {
        if (account == address(0)) {
            revert DelMundo__NullAddressError();
        }
        uint256 amount = address(this).balance;
        emit DelMundo__Withdraw(account, amount);
        (bool success, ) = payable(account).call{value: amount}("");
        require(success,"Withdraw failed");
    }
}
