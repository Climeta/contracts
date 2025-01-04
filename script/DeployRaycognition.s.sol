// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Raycognition} from "../src/token/Raycognition.sol";

contract DeployRaycognition is Script {
    function run(address _admin) public returns (address) {
        Raycognition raycog = new Raycognition(_admin);
        return address(raycog);
    }

}