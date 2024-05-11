// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {RayWallet} from "../src/RayWallet.sol";


contract DeployRayWallet is Script {

    function run() external returns (address) {
        RayWallet rayWallet = new RayWallet();
        return (address(rayWallet));
    }
}