// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DelMundo} from "../src/token/DelMundo.sol";


contract DeployDelMundo is Script {

    function deploy(address _admin) external returns (address) {
        DelMundo delMundo = new DelMundo(_admin);
        return (address(delMundo));
    }

    function run() external returns (address) {
        address admin = vm.envAddress("OWNER_PUBLIC_KEY");
        DelMundo delMundo = new DelMundo(admin);
        delMundo = DelMundo(address(delMundo));
        return (address(delMundo));
    }
}