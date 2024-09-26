/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployDelMundo} from "./DeployDelMundo.s.sol";
import {DeployRayward} from "./DeployRayward.s.sol";
import {DeployClimetaDiamond} from "./DeployClimetaDiamond.s.sol";
import {DeployRayputation} from "./DeployRayputation.s.sol";
import {DeployTokenBoundRegistry} from "./DeployTokenBoundRegistry.s.sol";
import {DeployDiamondFacets} from "./DeployDiamondFacets.s.sol";
import {IERC6551Registry} from "@tokenbound/erc6551/interfaces/IERC6551Registry.sol";
import {DeployRayWallet} from "./DeployRayWallet.s.sol";

contract DeployAll is Script {
    address public admin;
    address public delMundoAddr;
    address public raywardAddr;
    address public rayputationAddr;
    address public wallet;
    address public registryAddr;
    uint256 public chainId;
    address public rayWallet;
    address public diamondcut;
    address public diamondLoupe;
    address public ownership;

    constructor(){
    }

    function run() external {
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is admin and address [0] from anvil
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        admin = vm.envAddress("DEPLOYER_PUBLIC_KEY");

        vm.startBroadcast(deployerPrivateKey);
        DeployDelMundo delMundo = new DeployDelMundo();
        delMundoAddr = delMundo.run(admin);
        console.log("DELMUNDO_ADDRESS=", delMundoAddr);

        DeployRayward rayward = new DeployRayward();
        raywardAddr = rayward.run(admin);

        DeployRayputation rayputation = new DeployRayputation();
        rayputationAddr = rayputation.deploy(admin);

        DeployRayWallet deployWallet = new DeployRayWallet();
        wallet = deployWallet.run();

        DeployTokenBoundRegistry registry = new DeployTokenBoundRegistry();
        registryAddr = registry.run();
        chainId = vm.envUint("CHAINID");
        rayWallet = IERC6551Registry(registryAddr).account(wallet, 0, chainId, delMundoAddr, 0);

        DeployDiamondFacets coreFacets = new DeployDiamondFacets();
        (diamondcut, diamondLoupe, ownership) = coreFacets.run();

//        DeployClimetaDiamond deployClimeta = new DeployClimetaDiamond();
//        deployClimeta.run();

        vm.stopBroadcast();
    }
}
