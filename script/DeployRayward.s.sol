// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Rayward} from "../src/token/Rayward.sol";


contract DeployRayward is Script {

    function run() external returns (address) {
        address admin = vm.envAddress("OWNER_PUBLIC_KEY");
        Rayward rayward = new Rayward(admin);
        return (address(rayward));
    }

    function deploy(address _admin) external returns (address) {
        Rayward rayward = new Rayward(_admin);
        return (address(rayward));
    }
}