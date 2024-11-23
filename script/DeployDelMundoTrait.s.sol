// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DelMundoTrait} from "../src/token/DelMundoTrait.sol";


contract DeployDelMundoTrait is Script {

    function deploy(address _admin) external returns (address) {
        DelMundoTrait delMundoTrait = new DelMundoTrait(_admin);
        return (address(delMundoTrait));
    }

    function run() external returns (address) {
        address admin = vm.envAddress("OWNER_PUBLIC_KEY");
        DelMundoTrait delMundoTrait = new DelMundoTrait(admin);
        delMundoTrait = DelMundoTrait(address(delMundoTrait));
        return (address(delMundoTrait));
    }
}