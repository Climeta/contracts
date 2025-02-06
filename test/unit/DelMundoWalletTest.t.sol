// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/DelMundoWallet.sol";
import "../../src/token/DelMundo.sol";
import {ERC6551Registry} from "@tokenbound/erc6551/ERC6551Registry.sol";
import {DeployDelMundoWallet} from "../../script/DeployDelMundoWallet.s.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {DeployTokenBoundRegistry} from "../../script/DeployTokenBoundRegistry.s.sol";

import "../utils/CallTest.sol";


contract DelMundoWalletTest is Test, IERC721Receiver {
    event TransactionExecuted(address indexed target, uint256 indexed value, bytes data);

    ERC6551Registry registry;
    DelMundoWallet rayWallet;
    DelMundo delMundo;
    CallTest callTest;
    address user1;
    uint256 user1Pk;
    address user2;
    uint256 user2Pk;
    address admin;

    function setUp() public {
        callTest = new CallTest();

        admin = makeAddr("admin");
        DeployTokenBoundRegistry registryDeployer = new DeployTokenBoundRegistry();
        registry = ERC6551Registry(registryDeployer.run());

        DeployDelMundoWallet rayWalletDeployer = new DeployDelMundoWallet();
        rayWallet = DelMundoWallet(payable(rayWalletDeployer.run()));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));
        address current = address(this);
        vm.prank(admin);
        delMundo.addAdmin(current);

        (user1, user1Pk) = makeAddrAndKey("user1");
        (user2, user2Pk) = makeAddrAndKey("user2");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function test_Interfaces() public {
        assertEq(rayWallet.iAmADelMundoWallet(), true);
        assertEq(rayWallet.onERC1155Received(address(0),address(0),0,0,'0x'), IERC1155Receiver.onERC1155Received.selector);
        uint256[] memory arr1;
        assertEq(rayWallet.onERC1155BatchReceived(address(0),address(0),arr1,arr1,'0x'), IERC1155Receiver.onERC1155BatchReceived.selector);
    }

    function test_Ownership() public {
        delMundo.safeMint(address(this), 0, "uri-0");
        delMundo.safeMint(user1, 1, "uri-1");
        delMundo.safeMint(user2, 2, "uri-2");
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);
        address account2 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 2);
        assertEq(account0, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 0));
        assertEq(account1, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 1));
        assertEq(account2, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 2));

        assertEq(DelMundoWallet(payable(account0)).owner(), address(this));
        assertEq(DelMundoWallet(payable(account1)).owner(), user1);
        assertEq(DelMundoWallet(payable(account2)).owner(), user2);

        // Check different chain
        vm.chainId(1111);
        assertEq(DelMundoWallet(payable(account0)).owner(), address(0));
        assertEq(DelMundoWallet(payable(account1)).owner(), address(0));
        assertEq(DelMundoWallet(payable(account2)).owner(), address(0));
        vm.chainId(31337);
    }

    function test_SupportsInterface() public view {
        assertEq(rayWallet.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(rayWallet.supportsInterface(type(IDelMundoWallet).interfaceId), true);
        assertEq(rayWallet.supportsInterface(type(IDelMundoWallet).interfaceId), true);
    }

    function test_ExecuteCall() public {
        delMundo.safeMint(admin, 0, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);

        string memory callTestAbi = "callMe(uint256)";
        bytes memory callTestCallData = abi.encodeWithSignature(callTestAbi, 10);
        vm.startPrank(admin);
        vm.expectEmit(true, true, false, true);
        emit TransactionExecuted(address(callTest), 0, callTestCallData);
        DelMundoWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        vm.stopPrank();
        assertEq(callTest.lastCaller(), account0);
        assertEq(callTest.lastValue(), 10);
    }

    function test_Token() public {
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);

        (uint256 chainId, address tokenContract, uint256 tokenId) = DelMundoWallet(payable(account0)).token();
        assertEq(chainId, block.chainid);
        assertEq(tokenContract, address(delMundo));
        assertEq(tokenId, 0);
        (chainId, tokenContract, tokenId) = DelMundoWallet(payable(account1)).token();
        assertEq(chainId, block.chainid);
        assertEq(tokenContract, address(delMundo));
        assertEq(tokenId, 1);
    }

    function test_Nonce() public {
        delMundo.safeMint(admin, 0, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);

        string memory callTestAbi = "callMe(uint256)";
        bytes memory callTestCallData = abi.encodeWithSignature(callTestAbi, 10);

        assertEq(DelMundoWallet(payable(account0)).nonce(), 0);
        vm.startPrank(admin);
        DelMundoWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        vm.stopPrank();
        assertEq(DelMundoWallet(payable(account0)).nonce(), 1);
        // Test nonce is not updated on a reverted transaction
        vm.expectRevert();
        DelMundoWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        assertEq(DelMundoWallet(payable(account0)).nonce(), 1);
        // Test it increments again
        vm.startPrank(admin);
        DelMundoWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        vm.stopPrank();
        assertEq(DelMundoWallet(payable(account0)).nonce(), 2);
    }


    function test_IsValidSignature() public {

        vm.prank(admin);
        delMundo.enableResell();

        (address signer, uint256 signerPk) = makeAddrAndKey("signer");
        delMundo.safeMint(signer, 0, "ray-uri");
        delMundo.safeMint(user1, 1, "delmundo1-uri");
        delMundo.safeMint(user2, 2, "delmundo2-uri");
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);
        address account2 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 2);

        string memory clearText = "Hello, World!";
        bytes32 digest = keccak256(abi.encodePacked(clearText));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(DelMundoWallet(payable(address(account0))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);

        clearText = "I own DelMundo 1";
        digest = keccak256(abi.encodePacked(clearText));
        (v, r, s) = vm.sign(user1Pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertEq(DelMundoWallet(payable(address(account1))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
        (v, r, s) = vm.sign(user2Pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertNotEq(DelMundoWallet(payable(address(account1))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);

        clearText = "I own DelMundo 2";
        digest = keccak256(abi.encodePacked(clearText));
        (v, r, s) = vm.sign(user1Pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertNotEq(DelMundoWallet(payable(address(account2))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
        (v, r, s) = vm.sign(user2Pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertEq(DelMundoWallet(payable(address(account2))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);

        // Test move DelMundo from user1 to user2
        vm.prank(user1);
        delMundo.safeTransferFrom(user1, user2, 1);
        assertEq(delMundo.ownerOf(1), user2);

        clearText = "I own DelMundo 1";
        digest = keccak256(abi.encodePacked(clearText));
        (v, r, s) = vm.sign(user1Pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertNotEq(DelMundoWallet(payable(address(account1))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
        (v, r, s) = vm.sign(user2Pk, digest);
        signature = abi.encodePacked(r, s, v);
        assertEq(DelMundoWallet(payable(address(account1))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
    }

    function test_IsNotValidSignature() public {
        (, uint256 notSignerPk) = makeAddrAndKey("not-signer");
        (address signer, ) = makeAddrAndKey("signer");
        delMundo.safeMint(signer, 0, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);

        string memory clearText = "Hello, World!";
        bytes32 digest = keccak256(abi.encodePacked(clearText));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(notSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertNotEq(DelMundoWallet(payable(address(account0))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
    }


}