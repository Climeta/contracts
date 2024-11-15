// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {Raycognition} from "../src/token/Raycognition.sol";

contract DeployRaycognition is Script {

    function deploy(address _admin) external returns (address) {
        Raycognition raycognition = new Raycognition(_admin);
        return (address(raycognition));
    }

    function run() external {
        address admin = vm.envAddress("OWNER_PUBLIC_KEY");
        address raycognition = this.deploy(admin);
        console.log("RAYCOGNITION_ADDRESS=", raycognition);
    }

}