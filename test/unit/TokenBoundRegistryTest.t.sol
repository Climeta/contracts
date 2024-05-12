// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {ERC6551Registry} from "../test/utils/tokenbound/reference/src/ERC6551Registry.sol";
import {DeployTokenBoundRegistry} from "../../script/DeployTokenBoundRegistry.s.sol";

contract TokenBoundRegistryTest is Test {
    ERC6551Registry registry;

    function setup() {
        DeployTokenBoundRegistry deployer = new DeployTokenBoundRegistry();
        registry = ERC6551Registry(deployer.run());
    }

}