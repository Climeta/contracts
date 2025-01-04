// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DelMundoWallet} from "../src/DelMundoWallet.sol";


contract DeployDelMundoWallet is Script {
    function run() public returns (address) {
        DelMundoWallet delMundoWallet = new DelMundoWallet();
        return (address(delMundoWallet));
    }
}