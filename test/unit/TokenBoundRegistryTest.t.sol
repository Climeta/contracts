// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/RayWallet.sol";
import "../../src/token/DelMundo.sol";
import {ERC6551Registry} from "@tokenbound/erc6551/ERC6551Registry.sol";
import {DeployTokenBoundRegistry} from "../../script/DeployTokenBoundRegistry.s.sol";
import {DeployRayWallet} from "../../script/DeployRayWallet.s.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";

contract TokenBoundRegistryTest is Test {
    ERC6551Registry registry;
    address constant RAY_WALLET_0 = 0x8BB538D8162C84Af471553bD7AE228FF4aD25519;
    RayWallet rayWallet;
    DelMundo delMundo;
    address private admin;

    function setUp () public {
        admin = makeAddr("admin");
        DeployTokenBoundRegistry deployer = new DeployTokenBoundRegistry();
        registry = ERC6551Registry(deployer.run());

        DeployRayWallet rayWalletDeployer = new DeployRayWallet();
        rayWallet = RayWallet(payable(rayWalletDeployer.run()));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));
    }

    function test_Account() public {
        address account = registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        assertEq(account, RAY_WALLET_0);
    }

    function test_CreateAccount() public {
        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);
        address account2 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 2);
        assertEq(account0, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 0));
        assertEq(account1, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 1));
        assertEq(account2, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 2));
    }
}