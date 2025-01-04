// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DelMundoTrait} from "../src/token/DelMundoTrait.sol";


contract DeployDelMundoTrait is Script {
    function run(address _admin, address _climeta) public returns (address) {
        DelMundoTrait delMundoTrait = new DelMundoTrait(_admin, _climeta);
        return (address(delMundoTrait));
    }
}