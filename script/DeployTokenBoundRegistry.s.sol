// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC6551Registry} from "../test/utils/tokenbound/reference/src/ERC6551Registry.sol";
import {DeployRegistry} from "../test/utils/tokenbound/reference/script/DeployRegistry.s.sol";


contract DeployTokenBoundRegistry is Script {

    function run() external returns (address) {
        DeployRegistry registryDeployer = new DeployRegistry();
        return (registryDeployer.run());
    }
}