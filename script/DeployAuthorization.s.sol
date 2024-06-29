// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Authorization} from "../src/Authorization.sol";


contract DeployAuthorization is Script {

    function run(address admin, address payable opsTreasury, address payable climetaCore) external returns (address) {
        vm.startBroadcast();
        Authorization auth = new Authorization();
        auth.initialize(admin, opsTreasury, climetaCore);
        vm.stopBroadcast();
        return (address(auth));
    }
}