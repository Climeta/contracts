// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DelMundo} from "../src/token/DelMundo.sol";


contract DeployDelMundo is Script {
    function run(address _admin) public returns (address) {
        DelMundo delMundo = new DelMundo(_admin);
        return (address(delMundo));
    }
}