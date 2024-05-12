// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/ERC6551Registry.sol";
import "../../src/RayWallet.sol";
import "../../src/token/DelMundo.sol";
import {DeployERC6551Registry} from "../../script/DeployERC6551Registry.s.sol";
import {DeployRayWallet} from "../../script/DeployRayWallet.s.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";

contract ERC6551RegistryTest is Test {
    ERC6551Registry registry;
    RayWallet rayWallet;
    DelMundo delMundo;
    address private admin;

    address constant RAY_WALLET_0 = 0x8BB538D8162C84Af471553bD7AE228FF4aD25519;

    function setUp() public {
        admin = makeAddr("admin");
        DeployERC6551Registry registryDeployer = new DeployERC6551Registry();
        registry = ERC6551Registry(registryDeployer.run());

        DeployRayWallet rayWalletDeployer = new DeployRayWallet();
        rayWallet = RayWallet(payable(rayWalletDeployer.run()));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));

    }

    function test_Account() public {
        address account = registry.account(address(rayWallet), block.chainid, address(delMundo), 0, 0);
        assertEq(account, RAY_WALLET_0);
    }

    function test_CreateAccount() public {
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");
        address account1 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 1, 0, "");
        address account2 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 2, 0, "");
        assertEq(account0, registry.account(address(rayWallet), block.chainid, address(delMundo), 0, 0));
        assertEq(account1, registry.account(address(rayWallet), block.chainid, address(delMundo), 1, 0));
        assertEq(account2, registry.account(address(rayWallet), block.chainid, address(delMundo), 2, 0));
    }
}