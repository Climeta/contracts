// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {VmSafe} from "../../lib/forge-std/src/Vm.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract DelMundoTest is Test, IERC721Receiver, EIP712 {
    DelMundo private delMundo;
    uint256 private tokenIdToTest = 0;
    address payable private treasury;
    string private tokenUriToTest = "https://token.uri/";
    uint256 constant MAX_SUPPLY = 1000;
    uint256 constant MAX_PER_WALLET = 20;
    address private admin;
    uint256 private adminPk;

    string private constant SIGNING_DOMAIN = "RayNFT-Voucher";
    string private constant SIGNATURE_VERSION = "1";
    uint256 private constant MIN_PRICE = 100000000000;
    bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
        delMundo.setTreasuryAddress(treasury);
    }

    function test_AddAdmin() public {
        address newAdmin = makeAddr("new-admin");
        delMundo.addAdmin(newAdmin);
        assert(delMundo.hasRole(delMundo.RAY_ROLE(), newAdmin));
    }

    function test_RevokeAdmin() public {
        address newAdmin = makeAddr("new-admin");
        delMundo.addAdmin(newAdmin);
        assert(delMundo.hasRole(delMundo.RAY_ROLE(), newAdmin));
        delMundo.revokeAdmin(newAdmin);
        assert(!delMundo.hasRole(delMundo.RAY_ROLE(), newAdmin));
    }



    function test_CurrentMaxSupply() public view {
        assertEq(delMundo.currentMaxSupply(), MAX_SUPPLY);
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
        bytes32 VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory voucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, _voucherData.minPrice, voucherSignature);

        // Let's redeem it!
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        delMundo.redeem{value: 1 ether}(voucher);
        assertEq(delMundo.ownerOf(_voucherData.tokenId), user1);

    }

    function testFuzz_RedeemOnTheCheap(uint256 prices) public {
        // Let's create some vouchers!
        vm.assume(prices < 1000000000000000000);

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");
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
        vm.assume(prices < 1000000000000000000);

        bytes32 domainSeparatorHash = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes(SIGNING_DOMAIN)),
            keccak256(bytes(SIGNATURE_VERSION)),
            block.chainid,
            address(delMundo)
        ));

        VoucherData memory _voucherData = VoucherData(1, "https://token.uri/", 1 ether);
        bytes32 VOUCHER_TYPEHASH = keccak256("NFTVoucher(uint256 tokenId,string uri,uint256 minPrice)");
        bytes32 dataEncoded = keccak256(abi.encode(VOUCHER_TYPEHASH,_voucherData.tokenId,keccak256(bytes(_voucherData.uri)),_voucherData.minPrice));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparatorHash, dataEncoded));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(adminPk, digest);
        // this rsv combo is correct
        bytes memory voucherSignature = abi.encodePacked(r,s,v);
        DelMundo.NFTVoucher memory tamperedVoucher = DelMundo.NFTVoucher(_voucherData.tokenId, _voucherData.uri, prices, voucherSignature);

        // Let's try and redeem it on the cheap!
        address user1 = makeAddr("user1");
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSelector(DelMundo.DelMundo__IncorrectSigner.selector));
        delMundo.redeem{value: prices}(tamperedVoucher);
    }

    function expectCustomError(bytes4 selector, function() external func) public {
        (bool success,) = address(this).call(abi.encodeWithSignature("executeCall(function() external)", func));
        if (success) {
            fail("Expected revert not received");
        }

        string memory message = vm.error();
        bytes4 errorSelector = bytes4(keccak256(bytes(message.substring(0, message.indexOf("(")))));
        if (errorSelector != selector) {
            fail("Revert reason didn't match expected error");
        }
    }

    function executeCall(function() external func) public {
        func();
    }
    function test_SafeMint() public {
        vm.expectEmit(true, false, false, true, address(delMundo));
        emit DelMundo.minted(0, tokenUriToTest, address(this));
        delMundo.safeMint(address(this), tokenUriToTest);
        assertEq(delMundo.ownerOf(tokenIdToTest), address(this));
        assertEq(delMundo.tokenURI(tokenIdToTest), tokenUriToTest);
    }

    function test_SafeMintWithoutPermision() public {
        vm.expectRevert();
        delMundo.safeMint(address(0), tokenUriToTest);
    }

    function test_UpdateMaxSupply() public {
        delMundo.updateMaxSupply(MAX_SUPPLY*2);
        assertEq(delMundo.currentMaxSupply(), MAX_SUPPLY*2);
    }

    function test_MaxSupply() public {
        // Set to low value so it will fail when trying to mint new one
        delMundo.updateMaxSupply(1);
        delMundo.safeMint(address(this), "uri-0");
        delMundo.safeMint(address(this), "uri-1");
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);

        // Increase by 1 and confirm
        delMundo.safeMint(address(this), "uri-2");
        delMundo.updateMaxSupply(2);
        delMundo.safeMint(address(this), "uri-2");
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), "uri-3");

        // Increase by lots and confirm all good
        delMundo.updateMaxSupply(10);
        delMundo.safeMint(address(this), "uri-3");
        delMundo.safeMint(address(this), "uri-4");
        delMundo.safeMint(address(this), "uri-5");

        // Set to value lower than current supply and test
        delMundo.updateMaxSupply(1);
        vm.expectRevert(DelMundo.DelMundo__SoldOut.selector);
        delMundo.safeMint(address(this), "uri-6");
    }

    function test_UpdateMaxSupplyWithoutPermission() public {
        vm.prank(address(1));
        vm.expectRevert();
        delMundo.updateMaxSupply(MAX_SUPPLY*2);
    }

    function test_UpdateMaxPerWalletAmount() public {
        delMundo.updateMaxPerWalletAmount(MAX_PER_WALLET+10);
        assertEq(delMundo.maxPerWalletAmount(), MAX_PER_WALLET+10);
    }

    function test_UpdateMaxPerWalletAmountWithoutPermission() public {
        vm.prank(address(1));
        vm.expectRevert();
        delMundo.updateMaxPerWalletAmount(MAX_PER_WALLET+10);
    }

    function test_Withdraw() public {
        // Put 10 ETH in DelMundo and check that the withdraw function moves it to the treasury address
        deal(address(delMundo), 10 ether);
        delMundo.withdraw();
        uint256 balanceAfter = treasury.balance;
        assertEq(balanceAfter, 10 ether);
    }

    function test_WithdrawWithoutPermission() public {
        delMundo.renounceRole(delMundo.RAY_ROLE(), address(this));
        vm.expectRevert();
        delMundo.withdraw();
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

        delMundo.safeMint(user1, "uri-0");
        delMundo.safeMint(user1, "uri-1");
        tokens = delMundo.tokensOfOwner(user1);
        assertEq(tokens.length, 2);
    }

    function test_Pause() public {
        // creating a signed digest for testing
        delMundo.safeMint(address(this), "uri-0");
        delMundo.pause();
        vm.expectRevert(Pausable.EnforcedPause.selector);
        delMundo.safeMint(address(this), "uri-1");
        delMundo.unpause();
        delMundo.safeMint(address(this), "uri-1");
    }

    function test_SetTreasury() public {
        address payable old_treasury = delMundo._treasury();
        address payable new_treasury = payable(makeAddr("new-treasury"));
        delMundo.setTreasuryAddress(new_treasury);
        assertEq(delMundo._treasury(), new_treasury);

        // ensure only owner can update!
        address payable naughtyOne = payable(makeAddr("naughtyboy"));
        vm.prank(naughtyOne);
        vm.expectRevert(abi.encodeWithSelector(DelMundo.DelMundo__NotRay.selector, naughtyOne));
        delMundo.setTreasuryAddress(naughtyOne);
    }
}