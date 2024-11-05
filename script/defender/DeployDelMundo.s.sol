// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {DelMundo} from "../../src/token/DelMundo.sol";

import {Defender} from "openzeppelin-foundry-upgrades/Defender.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        address admin = vm.envAddress("ADMIN_ADDRESS");
        string memory uri = vm.envString("URI");
        address deployed = Defender.deployContract("DelMundo.sol", abi.encode(admin));
        console.log("Deployed contract to address", deployed);
    }
}
