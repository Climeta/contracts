// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ERC6551Registry} from "../src/ERC6551Registry.sol";


contract DeployERC6551Registry is Script {

    function run() external returns (address) {
        ERC6551Registry registry = new ERC6551Registry();
        return (address(registry));
    }
}