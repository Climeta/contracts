// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import {IDonation} from "../src/interfaces/IDonation.sol";
import {IVoting} from "../src/interfaces/IVoting.sol";

contract InterfaceIdCalculator is Script {

    function run() external {
        console.log("########## InterfaceIds ##########");
        console.log("IAdmin");
        console.logBytes4(type(IAdmin).interfaceId);
        console.log("IDonation");
        console.logBytes4(type(IDonation).interfaceId);
        console.log("IVoting");
        console.logBytes4(type(IVoting).interfaceId);
    }
}