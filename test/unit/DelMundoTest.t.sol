// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {DelMundoWallet} from "../../src/DelMundoWallet.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC721Royalty} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import {ERC721Enumerable, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract DelMundoTest is Test, IERC721Receiver, EIP712 {

    event DelMundo__Minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);
    event Transfer(address from,address to ,uint256 tokenId);

    DelMundo private delMundo;
    address payable private treasury;
    string constant tokenUriToTest = "https://token.uri/";
    string constant tokenUriToTest2 = "https://token.uri2/";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 5;
    address private admin;
    uint256 private adminPk;

    string private constant SIGNING_DOMAIN = "DelMundo-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    uint256 private constant MIN_PRICE = 100000000000;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");

    struct VoucherData {
        uint256 tokenId;
        string uri;
        uint256 minPrice;
    }

    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

     function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function setUp() public {
        (admin, adminPk) = makeAddrAndKey("admin");
        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));
        address current = address(this);

        vm.prank(admin);
        delMundo.addAdmin(current);

        treasury = payable(makeAddr("treasury"));
        vm.prank(admin);
        delMundo.setDefaultRoyalties(treasury, 1000);

    }

    function test_Basics() public view {
        assertEq(delMundo.s_maxPerWalletAmount(), MAX_PER_WALLET);
        assertEq(delMundo.s_currentMaxSupply(), MAX_SUPPLY);
        assertFalse(delMundo.s_isTokenMinted(0));
        assertTrue(ERC165Checker.supportsInterface(address(delMundo), type(ERC721Royalty).interfaceId));
        assertTrue(ERC165Checker.supportsInterface(address(delMundo), type(ERC721Enumerable).interfaceId));
        assertTrue(ERC165Checker.supportsInterface(address(delMundo), type(ERC721).interfaceId));
        assertTrue(ERC165Checker.supportsInterface(address(delMundo), type(AccessControl).interfaceId));
        assertTrue(ERC165Checker.supportsInterface(address(delMundo), type(ERC721URIStorage).interfaceId));
    }

    function testFuzz_publicVariables(uint256 tokenid) public view {
        assertFalse(delMundo.s_isTokenMinted(tokenid));
    }

    function test_AddAdmin() public {
        address newAdmin = makeAddr("new-admin");
        address newerAdmin = makeAddr("newer-admin");

        vm.expectEmit();
        emit DelMundo.DelMundo__AdminAdded(newAdmin);
        delMundo.addAdmin(newAdmin);
        assert(delMundo.hasRole(delMundo.ADMIN_ROLE(), newAdmin));
        // test if new admin can add admins
        vm.prank(newAdmin);
        vm.expectEmit();
        emit DelMundo.DelMundo__AdminAdded(newerAdmin);
        delMundo.addAdmin(newerAdmin);
    }

    function test_RevokeAdmin() public {
        address newAdmin = makeAddr("new-admin");

        vm.expectEmit();
        emit DelMundo.DelMundo__AdminAdded(newAdmin);
        delMundo.addAdmin(newAdmin);
        assert(delMundo.hasRole(delMundo.ADMIN_ROLE(), newAdmin));

        vm.expectEmit();
        emit DelMundo.DelMundo__AdminRevoked(newAdmin);
        delMundo.revokeAdmin(newAdmin);
        assert(!delMundo.hasRole(delMundo.ADMIN_ROLE(), newAdmin));
    }

    function test_CurrentMaxSupply() public view {
        assertEq(delMundo.s_currentMaxSupply(), MAX_SUPPLY);
    }

    function test_Redeem() public {
        // Let's create some vouchers!

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory voucher1 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        _voucherData = VoucherData(2, "https://token.uri2/", 2 ether);
        dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (v, r, s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory voucher2 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        _voucherData = VoucherData(3, "https://token.uri3/", 1 ether);
        dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (v, r, s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory voucher3 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        // Let's redeem them in reverse order!
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        emit DelMundo__Minted(2, "https://token.uri2/", user1);
        emit Transfer(address(0), admin, 2);
        emit Transfer(admin, user1, 2);
        delMundo.redeem{value: 2 ether}(voucher2);
        assertEq(delMundo.ownerOf(voucher2.tokenId), user1);

        // Try and redeem same voucher again
        address user2 = makeAddr("user2");
        vm.deal(user2, 10 ether);
        vm.prank(user2);
        vm.expectRevert(DelMundo.DelMundo__AlreadyMinted.selector);
        delMundo.redeem{value: 2 ether}(voucher2);
        assertEq(delMundo.ownerOf(voucher2.tokenId), user1);

        vm.prank(admin);
        vm.expectRevert(DelMundo.DelMundo__AlreadyMinted.selector);
        delMundo.safeMint(user2, voucher2.tokenId, voucher2.uri);

        vm.prank(user2);
        delMundo.redeem{value: 1 ether}(voucher1);
        assertEq(delMundo.ownerOf(voucher1.tokenId), user2);

        delMundo.updateMaxPerWalletAmount(1);
        assertEq(delMundo.tokensOfOwner(user1).length, 1);

        vm.prank(user1);
        vm.expectRevert(DelMundo.DelMundo__TooMany.selector);
        delMundo.redeem{value: 1 ether}(voucher3);

        delMundo.updateMaxPerWalletAmount(0);
        vm.prank(user1);
        vm.expectRevert(DelMundo.DelMundo__TooMany.selector);
        delMundo.redeem{value: 1 ether}(voucher3);

        delMundo.updateMaxPerWalletAmount(2);
        vm.prank(user1);
        delMundo.redeem{value: 1 ether}(voucher3);
        assertEq(delMundo.ownerOf(voucher3.tokenId), user1);
        assertEq(delMundo.tokensOfOwner(user1).length, 2);
    }

    struct Vouchers {
        DelMundo.NFTVoucher voucher1minter1;
        DelMundo.NFTVoucher voucher2minter1;
        DelMundo.NFTVoucher voucher1minter2;
        DelMundo.NFTVoucher voucher2minter2;
    }

    struct Accounts {
        address user1;
        address minter1;
        uint256 minter1Pk;
        address minter2;
        uint256 minter2Pk;
    }

    function test_MinterRoleSigning() public {
        // Let's create some vouchers!
        Vouchers memory vouchers;
        Accounts memory accounts;

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));
        // We are going to create new minters, make sure they don't work, add them in and test out combos.
        (accounts.minter1, accounts.minter1Pk) = makeAddrAndKey("minter1");
        (accounts.minter2, accounts.minter2Pk) = makeAddrAndKey("minter2");

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/1", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accounts.minter1Pk, digest);
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher1minter1 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        (v, r, s) = vm.sign(accounts.minter2Pk, digest);
        voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher1minter2 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        _voucherData = VoucherData(2, "https://token.uri/2", 1 ether);
        dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));

        (v, r, s) = vm.sign(accounts.minter1Pk, digest);
        voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher2minter1 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        (v, r, s) = vm.sign(accounts.minter2Pk, digest);
        voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher2minter2 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        // Let's redeem them in reverse order!
        accounts.user1 = makeAddr("user1");
        vm.deal(accounts.user1, 10 ether);

        vm.prank(accounts.user1);
        vm.expectRevert(DelMundo.DelMundo__IncorrectSigner.selector);
        delMundo.redeem{value: 1 ether}(vouchers.voucher1minter1);

        vm.prank(accounts.user1);
        vm.expectRevert(DelMundo.DelMundo__IncorrectSigner.selector);
        delMundo.redeem{value: 1 ether}(vouchers.voucher1minter2);

        vm.prank(admin);
        vm.expectEmit();
        emit DelMundo.DelMundo__MinterAdded(accounts.minter1);
        delMundo.addMinter(accounts.minter1);

        vm.prank(accounts.user1);
        vm.expectRevert(DelMundo.DelMundo__IncorrectSigner.selector);
        delMundo.redeem{value: 1 ether}(vouchers.voucher1minter2);

        vm.prank(accounts.user1);
        vm.expectEmit();
        emit DelMundo__Minted(1, "https://token.uri/1", accounts.user1);
        emit Transfer(address(0), accounts.minter1, 1);
        emit Transfer(accounts.minter1, accounts.user1, 1);
        delMundo.redeem{value: 1 ether}(vouchers.voucher1minter1);
        assertEq(delMundo.ownerOf(vouchers.voucher1minter1.tokenId), accounts.user1);

        vm.prank(admin);
        vm.expectEmit();
        emit DelMundo.DelMundo__MinterAdded(accounts.minter2);
        delMundo.addMinter(accounts.minter2);

        vm.prank(admin);
        vm.expectEmit();
        emit DelMundo.DelMundo__MinterRevoked(accounts.minter1);
        delMundo.revokeMinter(accounts.minter1);

        vm.prank(accounts.user1);
        vm.expectRevert(DelMundo.DelMundo__IncorrectSigner.selector);
        delMundo.redeem{value: 1 ether}(vouchers.voucher2minter1);

        vm.prank(accounts.user1);
        vm.expectEmit();
        emit DelMundo__Minted(2, "https://token.uri/2", accounts.user1);
        emit Transfer(address(0), accounts.minter2, 1);
        emit Transfer(accounts.minter2, accounts.user1, 1);
        delMundo.redeem{value: 1 ether}(vouchers.voucher2minter2);
        assertEq(delMundo.ownerOf(vouchers.voucher2minter2.tokenId), accounts.user1);
    }

    function test_transferToDifferentWallets() public {
        vm.prank(admin);
        delMundo.enableResell();

        delMundo.safeMint(address(this), 1, tokenUriToTest);
        address userB = makeAddr("userB");
        delMundo.transferFrom(address(this), userB, 1);
        assertEq(delMundo.ownerOf(1), userB);
    }

    function test_transferEmbargo() public {

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory voucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        // Let's try and redeem it on the cheap!
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
        delMundo.redeem{value: 1 ether}(voucher);
        vm.expectRevert(DelMundo.DelMundo__CannotMoveYet.selector);
        delMundo.transferFrom(user1, user2, 1);
        vm.stopPrank();

        vm.prank(admin);
        delMundo.enableResell();

        vm.prank(user1);
        delMundo.transferFrom(user1, user2, 1);
        assertEq(delMundo.ownerOf(1), user2);
    }

    function test_getRoyalty() public {
        delMundo.safeMint(address(this), 1, tokenUriToTest);
        (address receiver, uint256 royalty) = delMundo.royaltyInfo(1, 10_000);
        assertEq(receiver, treasury);
        assertEq(royalty, 1_000);
    }

    function test_transferToRayWallet() public {
        vm.prank(admin);
        delMundo.enableResell();

        delMundo.safeMint(address(this), 1, tokenUriToTest);
        DelMundoWallet raywallet1 = new DelMundoWallet();
        console.log("DelMundoWallet is one? ", raywallet1.iAmADelMundoWallet());
        vm.expectRevert(DelMundo.DelMundo__CannotMoveToDelMundoWallet.selector);
        delMundo.transferFrom(address(this), address(raywallet1), 1);
        vm.expectRevert(DelMundo.DelMundo__CannotMoveToDelMundoWallet.selector);
        delMundo.safeTransferFrom(address(this), address(raywallet1), 1);

        delMundo.approve(address(raywallet1), 1);
        vm.prank(address(raywallet1));
        vm.expectRevert(DelMundo.DelMundo__CannotMoveToDelMundoWallet.selector);
        delMundo.transferFrom(address(this), address(raywallet1), 1);
    }

    function testFuzz_RedeemOnTheCheap(uint256 prices) public {
        // Let's create some vouchers!
        vm.assume(prices < 1 ether);

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory voucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        // Let's try and redeem it on the cheap!
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        vm.expectRevert(DelMundo.DelMundo__InsufficientFunds.selector);
        delMundo.redeem{value: prices}(voucher);
    }

    function testFuzz_RedeemTamperWithVoucher(uint256 prices) public {
        // Let's create some vouchers!
        vm.assume(prices < 1 ether);

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);

        DelMundo.NFTVoucher memory cleanVoucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);
        DelMundo.NFTVoucher memory tamperedVoucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, prices, voucherSignature);

        // Let's try and redeem it on the cheap!
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
        vm.expectRevert(DelMundo.DelMundo__IncorrectSigner.selector);
        delMundo.redeem{value: prices}(tamperedVoucher);
        // ok, make sure clean voucher with right price works still
        delMundo.redeem{value: 1 ether}(cleanVoucher);
        vm.stopPrank();
        assertEq(delMundo.ownerOf(_voucherData.tokenId), user1);
    }

    function test_SafeMint() public {
        vm.expectEmit(true, false, false, true, address(delMundo));
        emit DelMundo__Minted(0, tokenUriToTest, address(this));
        delMundo.safeMint(address(this), 0, tokenUriToTest);
        assertEq(delMundo.ownerOf(0), address(this));
        assertEq(delMundo.tokenURI(0), tokenUriToTest);

        vm.expectEmit(true, false, false, true, address(delMundo));
        emit DelMundo__Minted(10, tokenUriToTest2, address(this));
        delMundo.safeMint(address(this), 10, tokenUriToTest2);
        assertEq(delMundo.ownerOf(10), address(this));
        assertEq(delMundo.tokenURI(10), tokenUriToTest2);

        // Some ERC721 tests
        assertEq(delMundo.balanceOf(address(this)), 2);
    }

    function test_SafeMintWithoutPermision() public {
        vm.prank(makeAddr("nonowner"));
        vm.expectRevert();
        delMundo.safeMint(address(0), 1, tokenUriToTest);
    }

    function test_UpdateMaxSupply() public {
        delMundo.updateMaxSupply(MAX_SUPPLY*2);
        assertEq(delMundo.s_currentMaxSupply(), MAX_SUPPLY*2);
    }

    function test_MaxSupply() public {
        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(2, "https://token.uri/2", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory cleanVoucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        // Set to low value so it will fail when trying to mint new one
        delMundo.updateMaxSupply(1);
        delMundo.safeMint(address(this), 0, "uri-0");
        delMundo.safeMint(address(this), 1, "uri-1");

        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);
        vm.startPrank(user1);
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.redeem{value: 1 ether}(cleanVoucher);
        vm.stopPrank();

        // Increase by 1 and confirm
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), 2, "uri-2");
        delMundo.updateMaxSupply(2);
        delMundo.safeMint(address(this), 2, "uri-2");
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), 3, "uri-3");

        // Increase by lots and confirm all good
        delMundo.updateMaxSupply(10);
        delMundo.safeMint(address(this), 3, "uri-3");
        delMundo.safeMint(address(this), 4, "uri-4");
        delMundo.safeMint(address(this), 5, "uri-5");

        // Set to value lower than current supply and test
        delMundo.updateMaxSupply(1);
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), 6, "uri-6");
    }

    function test_UpdateMaxSupplyWithoutPermission() public {
        vm.prank(address(1));
        vm.expectRevert();
        delMundo.updateMaxSupply(MAX_SUPPLY*2);
    }

    function test_UpdateMaxPerWalletAmount() public {
        delMundo.updateMaxPerWalletAmount(MAX_PER_WALLET+10);
        assertEq(delMundo.s_maxPerWalletAmount(), MAX_PER_WALLET+10);
    }

    function test_UpdateMaxPerWalletAmountWithoutPermission() public {
        vm.prank(address(1));
        vm.expectRevert();
        delMundo.updateMaxPerWalletAmount(MAX_PER_WALLET+10);
    }

    function test_Withdraw() public {
        // Put 10 ETH in DelMundo and check that the withdraw function moves it to the treasury address
        deal(address(delMundo), 10 ether);

        vm.expectRevert(DelMundo.DelMundo__NullAddressError.selector);
        delMundo.withdraw(payable(address(0)));

        delMundo.withdraw(treasury);
        uint256 balanceAfter = treasury.balance;
        assertEq(balanceAfter, 10 ether);
    }

    function test_WithdrawWithoutPermission() public {
        delMundo.renounceRole(delMundo.ADMIN_ROLE(), address(this));
        vm.expectRevert();
        delMundo.withdraw(payable(address(this)));
    }

    function test_SetContractURI() public {
        delMundo.setContractURI("http:testURI");
        string memory uri = delMundo.contractURI();
        assertEq(uri, "http:testURI");
        delMundo.setContractURI("http:testURI2");
        uri = delMundo.contractURI();
        assertEq(uri, "http:testURI2");
    }

    function test_SetContractURIFail() public {
        vm.prank(address(1));
        vm.expectRevert();
        delMundo.setContractURI("http:testURI");
    }

    function test_TokensOfOwner() public {
        address user1 = makeAddr("user1");
        uint256[] memory tokens = delMundo.tokensOfOwner(user1);
        assertEq(tokens.length, 0);

        delMundo.safeMint(user1, 0, "uri-0");
        delMundo.safeMint(user1, 1, "uri-1");
        tokens = delMundo.tokensOfOwner(user1);
        assertEq(tokens.length, 2);
    }

    function test_Pause() public {
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory cleanVoucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        delMundo.safeMint(address(this), 0, "uri-0");
        delMundo.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        delMundo.safeMint(address(this), 1, "uri-1");
        vm.startPrank(user1);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        delMundo.redeem{value: 1 ether}(cleanVoucher);
        vm.stopPrank();

        delMundo.unpause();
        delMundo.safeMint(address(this), 2, "uri-2");
        vm.startPrank(user1);
        delMundo.redeem{value: 1 ether}(cleanVoucher);
        vm.stopPrank();
    }
}