// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/DelMundoWallet.sol";
import "../../src/token/DelMundo.sol";
import {ERC6551Registry} from "@tokenbound/erc6551/ERC6551Registry.sol";
import {DeployTokenBoundRegistry} from "../../script/DeployTokenBoundRegistry.s.sol";
import {DeployDelMundoWallet} from "../../script/DeployDelMundoWallet.s.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";

contract TokenBoundRegistryTest is Test {
    ERC6551Registry registry;
    DelMundoWallet rayWallet;
    DelMundo delMundo;
    address private admin;

    function setUp () public {
        admin = makeAddr("admin");
        DeployTokenBoundRegistry deployer = new DeployTokenBoundRegistry();
        registry = ERC6551Registry(deployer.run());

        DeployDelMundoWallet rayWalletDeployer = new DeployDelMundoWallet();
        rayWallet = DelMundoWallet(payable(rayWalletDeployer.run()));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));
    }

    function test_CreateAccount() public {
        address calcAddress0 = registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        address calcAddress1 = registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 1);
        address calcAddress2 = registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 2);

        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);
        address account2 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 2);

        assertEq(account0, calcAddress0);
        assertEq(account1, calcAddress1);
        assertEq(account2, calcAddress2);
        assertEq(account1, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 1));
        assertEq(account2, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 2));
        assertEq(account0, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 0));
        assertEq(account1, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 1));
        assertEq(account2, registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 2));
    }
}