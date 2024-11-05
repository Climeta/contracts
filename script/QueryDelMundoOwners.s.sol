// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import {DelMundo} from "../src/token/DelMundo.sol";
import {IDiamondLoupe} from "../src//interfaces/IDiamondLoupe.sol";


contract QueryClimeta is Script {

    function run() external {
        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondLoupe climeta = IDiamondLoupe(climetaAddress);
        console.log("Climeta address", address(climeta));

        IAdmin climetaAdmin = IAdmin(climetaAddress);
        address delMundoAddr = climetaAdmin.getDelMundoAddress();
        console.log("DelMundo Address stored :", delMundoAddr);

        DelMundo delMundo = DelMundo(delMundoAddr);
        uint256 totalDelMundos = delMundo.totalSupply();
        console.log("Total minted :", totalDelMundos);

        for (uint256 i=0; i< totalDelMundos; i++) {
            console.log("Owner of ", i, " is " , delMundo.ownerOf(i));
        }

    }
}