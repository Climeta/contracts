// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
 * @title Membership NFT for Climeta
 * @author matt@climeta.io
 * @notice The DelMundo is an ERC721 NFT.
 * The metadata and images are stored on IPFS.
 * The metadata uris for each Del Mundo are completely distinct, there is no IPFs folder naming convention.
 * This is done because the images are premade and preloaded to IPFS and to preserve the anonymity of the next DelMundo till mint time
 * the uri for the metadata should not be guessable.
 * it uses some extensions so minting can be paused
 * @dev bugbounty contact mysaviour@climeta.io
 */
contract DelMundo is ERC721Enumerable, EIP712, ERC721URIStorage, ERC721Pausable, AccessControl {
    event DelMundo__Minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);

    error DelMundo__NotRay(address caller);
    error DelMundo__IncorrectSigner();
    error DelMundo__InsufficientFunds();
    error DelMundo__SoldOut();
    error DelMundo__TooMany();
    error DelMundo__AlreadyMinted();
    error DelMundo__NullAddressError();
    error DelMundo__CannotMoveToDelMundoWallet();

    bytes32 public constant RAY_ROLE = keccak256("RAY_ROLE");
    string public constant SIGNING_DOMAIN = "RayNFT-Voucher";
    string public constant SIGNING_VERSION = "1";
    bytes4 constant I_AM_DELMUNDO_WALLET = bytes4(keccak256("iAmADelMundoWallet()"));
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");

    uint256 public s_maxPerWalletAmount = 5;
    uint256 public s_currentMaxSupply = 1000;
    mapping (uint256 => bool) public s_isTokenMinted;

    struct NFTVoucher {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
        bytes signature;
    }

    constructor(address _admin)
    ERC721("DelMundo", "DEL-MUNDO")
    EIP712(SIGNING_DOMAIN, SIGNING_VERSION) {
        _grantRole(RAY_ROLE, _admin);
    }

    modifier onlyRay () {
        if (!hasRole(RAY_ROLE, msg.sender)) {
            revert DelMundo__NotRay(msg.sender);
        }
        _;
    }

    function addAdmin(address newAdmin) external onlyRay {
        _grantRole(RAY_ROLE, newAdmin);
    }
    function revokeAdmin(address oldAdmin) public onlyRay {
        require (msg.sender != oldAdmin, "Can't revoke yourself");
        _revokeRole(RAY_ROLE, oldAdmin);
    }
    function pause() public onlyRay {
        _pause();
    }
    function unpause() public onlyRay {
        _unpause();
    }
    function updateMaxSupply(uint256 newAmount) public onlyRay {
        s_currentMaxSupply = newAmount;
    }
    function updateMaxPerWalletAmount(uint256 newAmount) public onlyRay {
        s_maxPerWalletAmount = newAmount;
    }


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

    // OpenSea royalty information
    string private _contractURI;
    function setContractURI(string memory newURI) public onlyRay  {
        _contractURI = newURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // EIP712 Section

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
    /// @param voucher An NFTVoucher describing an unminted NFT.
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }

    /** @dev This is the core minting function.
     * The voucher is a pre signed message containing the tokenid of the NFT to mint as well as the metadata uri location on IPFS
     * The prefixed price is also included and signed so nothing can be tampered with.
     *
     * Once minted, the voucher cannot be replayed as the tokenId will be already minted. We manage the tokenids outside
     * NFTs and their ids outside the contract and provide randomised order vouchers to mmmbers.
     *
     * @param voucher NFTVoucher struct containing tokenId, ipfs metadatauri, price and the typed data signature.
     */
    function redeem(NFTVoucher calldata voucher) external payable returns (uint256) {
        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);
        // make sure that the signer is authorized to mint NFTs
        if (!hasRole(RAY_ROLE, signer)) {
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
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);
        emit DelMundo__Minted(voucher.tokenId, voucher.uri, msg.sender);

        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

        return voucher.tokenId;
    }

    function safeMint(address to, uint256 tokenId, string memory uri)
    external whenNotPaused onlyRay
    {
        if (s_isTokenMinted[tokenId]) {
            revert DelMundo__AlreadyMinted();
        }
        uint256 supply = totalSupply();
        if (supply > s_currentMaxSupply) {
            revert DelMundo__SoldOut();
        }
        s_isTokenMinted[tokenId] = true;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        emit DelMundo__Minted(tokenId, uri, to);
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    // @dev this overide prevents DelMundos from being moved to the ERC6551 locker wallet of another DelMundo.
    function _update (address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) returns(address) {
        bool isDelMundoWallet = ERC165Checker.supportsInterface(to, I_AM_DELMUNDO_WALLET);
        if (isDelMundoWallet) {
            revert DelMundo__CannotMoveToDelMundoWallet();
        }
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, AccessControl, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw(address payable account) public payable onlyRay {
        if (account == address(0)) {
            revert DelMundo__NullAddressError();
        }
        (bool success, ) = payable(account).call{value:address(this).balance}("");
        require(success,"Withdraw failed");
    }
}
