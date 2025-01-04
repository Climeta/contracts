// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import "@tokenbound/erc6551/ERC6551Registry.sol";

contract DeployTokenBoundRegistry is Script {
    function run() public returns (address) {
        ERC6551Registry registry = new ERC6551Registry();
        return (address(registry));
    }
}