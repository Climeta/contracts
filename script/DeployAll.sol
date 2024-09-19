// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {DeployDelMundo} from "./DeployDelMundo.s.sol";
import {DeployRayward} from "./DeployRayward.s.sol";
import {DeployRayputation} from "./DeployRayputation.s.sol";
import {DeployTokenBoundRegistry} from "./DeployTokenBoundRegistry.s.sol";
import {DeployDiamondFacets} from "./DeployDiamondFacets.s.sol";
import {IERC6551Registry} from "@tokenbound/erc6551/interfaces/IERC6551Registry.sol";
import {DeployRayWallet} from "./DeployRayWallet.s.sol";

contract DeployAll {
    constructor(){
    }

    function run() external {
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is admin and address [0] from anvil

        address admin = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        DeployDelMundo delMundo = new DeployDelMundo();
        address delMundoAddr = delMundo.run(admin);
        DeployRayward rayward = new DeployRayward();
        address raywardAddr = rayward.run(admin);

        DeployRayputation rayputation = new DeployRayputation();
        address rayputationAddr = rayputation.run(admin);

        DeployRayWallet deployWallet = new DeployRayWallet();
        address wallet = deployWallet.run();

        DeployTokenBoundRegistry registry = new DeployTokenBoundRegistry();
        address registryAddr = registry.run();
        address rayWallet = IERC6551Registry(registryAddr).account(wallet, 0, 31337, delMundoAddr, 0);

        DeployDiamondFacets coreFacets = new DeployDiamondFacets();
        (address diamondcut, address diamondLoupe, address ownership) = coreFacets.run();

//        DeployClimetaDiamond deployClimeta = new DeployClimetaDiamond();
//        address climeta = deployClimeta.run();

    }
}
