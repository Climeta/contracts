// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/ERC6551Registry.sol";
import "../../src/RayWallet.sol";
import "../../src/token/DelMundo.sol";
import {DeployERC6551Registry} from "../../script/DeployERC6551Registry.sol";
import {DeployRayWallet} from "../../script/DeployRayWallet.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../utils/CallTest.sol";


contract RayWalletTest is Test, IERC721Receiver {
    ERC6551Registry registry;
    RayWallet rayWallet;
    DelMundo delMundo;
    CallTest callTest;
    address user1;
    address user2;
    address admin;

    function setUp() public {
        callTest = new CallTest();

        admin = makeAddr("admin");
        DeployERC6551Registry registryDeployer = new DeployERC6551Registry();
        registry = ERC6551Registry(registryDeployer.run());

        DeployRayWallet rayWalletDeployer = new DeployRayWallet();
        rayWallet = RayWallet(payable(rayWalletDeployer.run()));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));
        address current = address(this);
        vm.prank(admin);
        delMundo.addAdmin(current);

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function test_IsValidRayWallet() public view {
        assertEq(rayWallet.iAmADelMundoWallet(), true);
    }

    function test_Ownership() public {
        delMundo.safeMint(address(this), "uri-0");
        delMundo.safeMint(user1, "uri-1");
        delMundo.safeMint(user2, "uri-2");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");
        address account1 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 1, 0, "");
        address account2 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 2, 0, "");
        assertEq(account0, registry.account(address(rayWallet), block.chainid, address(delMundo), 0, 0));
        assertEq(account1, registry.account(address(rayWallet), block.chainid, address(delMundo), 1, 0));
        assertEq(account2, registry.account(address(rayWallet), block.chainid, address(delMundo), 2, 0));

        assertEq(RayWallet(payable(account0)).owner(), address(this));
        assertEq(RayWallet(payable(account1)).owner(), user1);
        assertEq(RayWallet(payable(account2)).owner(), user2);
    }

    function test_SupportsInterface() public {
        assertEq(rayWallet.supportsInterface(type(IERC165).interfaceId), true);
        assertEq(rayWallet.supportsInterface(type(IDelMundoWallet).interfaceId), true);
        assertEq(rayWallet.supportsInterface(type(IRayWallet).interfaceId), true);
    }

    function test_ExecuteCall() public {
        delMundo.safeMint(admin, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");

        string memory callTestAbi = "callMe(uint256)";
        bytes memory callTestCallData = abi.encodeWithSignature(callTestAbi, 10);
        vm.startPrank(admin);
        vm.expectEmit(true, true, false, true);
        emit IRayWallet.TransactionExecuted(address(callTest), 0, callTestCallData);
        RayWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        vm.stopPrank();
        assertEq(callTest.lastCaller(), account0);
        assertEq(callTest.lastValue(), 10);
    }

    function test_Token() public {
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");
        address account1 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 1, 0, "");

        (uint256 chainId, address tokenContract, uint256 tokenId) = RayWallet(payable(account0)).token();
        assertEq(chainId, block.chainid);
        assertEq(tokenContract, address(delMundo));
        assertEq(tokenId, 0);
        (chainId, tokenContract, tokenId) = RayWallet(payable(account1)).token();
        assertEq(chainId, block.chainid);
        assertEq(tokenContract, address(delMundo));
        assertEq(tokenId, 1);
    }

    function test_Nonce() public {
        delMundo.safeMint(admin, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");

        string memory callTestAbi = "callMe(uint256)";
        bytes memory callTestCallData = abi.encodeWithSignature(callTestAbi, 10);

        assertEq(RayWallet(payable(account0)).nonce(), 0);
        vm.startPrank(admin);
        RayWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        vm.stopPrank();
        assertEq(RayWallet(payable(account0)).nonce(), 1);
        // Test nonce is not updated on a reverted transaction
        vm.expectRevert();
        RayWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        assertEq(RayWallet(payable(account0)).nonce(), 1);
        // Test it increments again
        vm.startPrank(admin);
        RayWallet(payable(account0)).executeCall(address(callTest), 0, callTestCallData);
        vm.stopPrank();
        assertEq(RayWallet(payable(account0)).nonce(), 2);
    }


    function test_IsValidSignature() public {
        (address signer, uint256 signerPk) = makeAddrAndKey("signer");
        delMundo.safeMint(signer, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");

        string memory clearText = "Hello, World!";
        bytes32 digest = keccak256(abi.encodePacked(clearText));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertEq(RayWallet(payable(address(account0))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
    }

    function test_IsNotValidSignature() public {
        (address notSigner, uint256 notSignerPk) = makeAddrAndKey("not-signer");
        (address signer, uint256 signerPk) = makeAddrAndKey("signer");
        delMundo.safeMint(signer, "ray-uri");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");

        string memory clearText = "Hello, World!";
        bytes32 digest = keccak256(abi.encodePacked(clearText));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(notSignerPk, digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        assertNotEq(RayWallet(payable(address(account0))).isValidSignature(digest, signature), IERC1271.isValidSignature.selector);
    }


}