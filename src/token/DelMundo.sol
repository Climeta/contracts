// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
pragma abicoder v2; // required to accept structs as function parameters

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

contract DelMundo is ERC721Enumerable, EIP712, ERC721URIStorage, ERC721Royalty, ERC721Pausable, AccessControl {
    event minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);
    error NotRay(address caller);
    error DelMundo__IncorrectSigner(address signer);
    error DelMundo__InsufficientFunds();
    error DelMundo__SoldOut();

    bytes32 public constant RAY_ROLE = keccak256("RAY_ROLE");
    string private constant SIGNING_DOMAIN = "RayNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    bytes4 constant I_AM_DELMUNDO_WALLET = bytes4(keccak256("iAmADelMundoWallet()"));

    address payable private _treasury;

    uint256 public maxPerWalletAmount = 20;
    uint256 public currentMaxSupply = 1000;
    uint256 private s_tokenId;


    struct NFTVoucher {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
        bytes signature;
    }

    constructor()
    ERC721("DelMundo", "DEL-MUNDO")
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
        _grantRole(RAY_ROLE, msg.sender);
        s_tokenId=0;
    }

    modifier onlyRay () {
        if (!hasRole(RAY_ROLE, msg.sender)) {
            revert NotRay(msg.sender);
        }
        _;
    }

    function pause() public onlyRay {
        _pause();
    }
    function unpause() public onlyRay {
        _unpause();
    }
    function updateMaxSupply(uint256 newAmount) public onlyRay {
        currentMaxSupply = newAmount;
    }
    function updateMaxPerWalletAmount(uint256 newAmount) public onlyRay {
        maxPerWalletAmount = newAmount;
    }
    /// @notice Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
    /// @param voucher An NFTVoucher to hash.
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)"),
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

    function redeem(NFTVoucher calldata voucher) public payable returns (uint256) {

        // make sure signature is valid and get the address of the signer
        address signer = _verify(voucher);

        // make sure that the signer is authorized to mint NFTs
        if (!hasRole(RAY_ROLE, signer)) {
            revert DelMundo__IncorrectSigner(signer);
        }

        // make sure that the redeemer is paying enough to cover the price
        if (msg.value < voucher.minPrice) {
            revert DelMundo__InsufficientFunds();
        }

        uint256 supply = totalSupply();
        if (supply > currentMaxSupply) {
            revert DelMundo__SoldOut();
        }

        // first assign the token to the signer, to establish provenance on-chain
        _mint(signer, voucher.tokenId);
        _setTokenURI(voucher.tokenId, voucher.uri);

        // transfer the token to the redeemer
        _transfer(signer, msg.sender, voucher.tokenId);

        // record payment to signer's withdrawal balance
        emit minted(voucher.tokenId, voucher.uri, msg.sender);
        unchecked{s_tokenId++;}

        return voucher.tokenId;
    }

    function safeMint(address to, string memory uri)
    public whenNotPaused onlyRay
    {
        uint256 supply = totalSupply();
        require(supply <= currentMaxSupply, "That's all folks");
        _safeMint(to, s_tokenId);
        _setTokenURI(s_tokenId, uri);
        emit minted(s_tokenId, uri, to);
        unchecked{s_tokenId++;}
    }

    function tokenURI(uint256 tokenId)
    public
    view
    override(ERC721, ERC721URIStorage)
    returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function royaltyInfo (uint256 _tokenId, uint256 _salePrice) public view override returns (address receiver, uint256 royaltyAmount) {
        // Pay Ops 10%
        require(_tokenId > 0, "Ray not for sale!");
        return (_treasury, _salePrice * 10/100);
    }

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function setTreasuryAddress(address payable account) external onlyRay {
        _treasury = account;
    }

    function _update (address to, uint256 tokenId, address auth) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) returns(address) {
        bool isDelMundoWallet = ERC165Checker.supportsInterface(to, I_AM_DELMUNDO_WALLET);
        require(!isDelMundoWallet, "Cannot transfer to a Del Mundo wallet");
        return super._update(to, tokenId, auth);
    }

    function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable, ERC721Royalty, AccessControl, ERC721URIStorage)
    returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function withdraw() public payable onlyRay {
        (bool success, ) = payable(_treasury).call{value:address(this).balance}("");
        require(success,"Withdraw failed");
    }
}
