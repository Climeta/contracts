// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Rayputation} from "../src/token/Rayputation.sol";

contract DeployRayputation is Script {

    function deploy(address _admin) external returns (address) {
        Rayputation rayputation = new Rayputation(_admin);
        return (address(rayputation));
    }

    function run() external {
        address admin = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        address rayputation = this.deploy(admin);
    }

}