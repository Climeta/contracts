// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {DelMundoTrait} from "../../src/token/DelMundoTrait.sol";
import {DelMundoWallet} from "../../src/DelMundoWallet.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {DeployDelMundoTrait} from "../../script/DeployDelMundoTrait.s.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DelMundoTraitTest is Test, IERC721Receiver, EIP712 {

    event DelMundo__Minted(uint256 indexed tokenId, string tokenURI, address ownerAddress);
    event Transfer(address from,address to ,uint256 tokenId);
    string constant tokenUriToTest = "https://token.uri/";
    string constant tokenUriToTest2 = "https://token.uri2/";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 5;
    string private constant SIGNING_DOMAIN = "RayNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    uint256 private constant MIN_PRICE = 100000000000;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 constant VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");

    DelMundo private delMundo;
    DelMundoTrait private delMundoTrait;

    struct Actors {
        address user1;
        address user2;
        address user3;
        address admin;
        uint256 adminPk;
        address payable treasury;
    }
    Actors private actors;

    struct Vouchers {
        DelMundo.NFTVoucher voucher1;
        DelMundo.NFTVoucher voucher2;
        DelMundo.NFTVoucher voucher3;
    }
    Vouchers private vouchers;

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
        (actors.admin, actors.adminPk) = makeAddrAndKey("admin");
        actors.treasury = payable(makeAddr("treasury"));
        actors.user1 = makeAddr("user1");
        actors.user2 = makeAddr("user2");
        actors.user3 = makeAddr("user3");

        vm.deal(actors.user1, 10 ether);
        vm.deal(actors.user2, 10 ether);
        vm.deal(actors.user3, 10 ether);

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.deploy( actors.admin));
        vm.prank(actors.admin);
        // 10% royalty for secondary sales
        delMundo.setDefaultRoyalties(actors.treasury, 1000);

        DeployDelMundoTrait delMundoTraitDeployer = new DeployDelMundoTrait();
        delMundoTrait = DelMundoTrait(delMundoTraitDeployer.deploy(actors.admin));

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
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(actors.adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher1 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        _voucherData = VoucherData(2, "https://token.uri2/", 1 ether);
        dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (v, r, s) = vm.sign(actors.adminPk, digest);
        // this rsv combo is correct
        voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher2 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        _voucherData = VoucherData(3, "https://token.uri3/", 1 ether);
        dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (v, r, s) = vm.sign(actors.adminPk, digest);
        // this rsv combo is correct
        voucherSignature = abi.encodePacked(r,s,v);
        vouchers.voucher3 = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        vm.prank(actors.user1);
        delMundo.redeem{value: 1 ether}(vouchers.voucher1);

        vm.prank(actors.user2);
        delMundo.redeem{value: 1 ether}(vouchers.voucher2);

        vm.prank(actors.user3);
        delMundo.redeem{value: 1 ether}(vouchers.voucher3);
    }

    function test_CreateNewTrait() public {
        string memory trait1URI = "Trait 1 URI";
        string memory trait2URI = "Trait 2 URI";

        // ensure only admin can set new values
        vm.prank(actors.user1);
        vm.expectRevert();
        delMundoTrait.setURI(1, trait1URI, 1_000);
        vm.prank(actors.user1);
        vm.expectRevert();
        delMundoTrait.mint(actors.user1, 1, "0x");

        // Create a new trait with 1000 supply
        vm.prank(actors.admin);
        delMundoTrait.setURI(1, trait1URI, 1_000);
        assertEq(delMundoTrait.maxSupply(1), 1_000);
        assertEq(delMundoTrait.uri(1), trait1URI);

        // ensure non admin can't mint a configured pre mint token
        vm.prank(actors.user1);
        vm.expectRevert();
        delMundoTrait.mint(actors.user1, 1, "0x");

        // Test can change before one is minted
        vm.startPrank(actors.admin);
        delMundoTrait.setURI(1, trait1URI, 2_000);
        assertEq(delMundoTrait.maxSupply(1), 2_000);
        delMundoTrait.mint(actors.admin, 1, "0x");
        assertEq(delMundoTrait.balanceOf(actors.admin, 1), 2_000);
        assertEq(delMundoTrait.maxSupply(1), 2_000);

        vm.expectRevert();
        vm.expectRevert(DelMundoTrait.DelMundoTraits__AlreadyMinted.selector);
        delMundoTrait.mint(actors.admin, 1, "0x");
        vm.expectRevert(DelMundoTrait.DelMundoTraits__AlreadyMinted.selector);
        delMundoTrait.setURI(1, trait1URI, 1_000);
        assertEq(delMundoTrait.maxSupply(1), 2_000);
        vm.stopPrank();

        vm.startPrank(actors.admin);
        vm.expectRevert(DelMundoTrait.DelMundoTraits__TokenNotConfigured.selector);
        delMundoTrait.mint(actors.admin, 2, "0x");
        vm.expectRevert(DelMundoTrait.DelMundoTraits__TokenNotConfigured.selector);
        delMundoTrait.mint(actors.admin, 0, "0x");
        vm.expectRevert(DelMundoTrait.DelMundoTraits__TokenNotConfigured.selector);
        delMundoTrait.mint(actors.admin, 200, "0x");

        delMundoTrait.setURI(2, trait2URI, 10_000);
        delMundoTrait.mint(actors.user1, 2, "0x");
        assertEq(delMundoTrait.balanceOf(actors.user1, 2), 10_000);
        assertEq(delMundoTrait.maxSupply(2), 10_000);
    }

}