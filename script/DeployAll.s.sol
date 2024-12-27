/// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployDelMundo} from "./DeployDelMundo.s.sol";
import {DeployDelMundoTrait} from "./DeployDelMundoTrait.s.sol";
import {DeployRayward} from "./DeployRayward.s.sol";
import {DeployClimetaDiamond} from "./DeployClimetaDiamond.s.sol";
import {DeployRaycognition} from "./DeployRaycognition.s.sol";
import {DeployTokenBoundRegistry} from "./DeployTokenBoundRegistry.s.sol";
import {DeployDiamondFacets} from "./DeployDiamondFacets.s.sol";
import {IERC6551Registry} from "@tokenbound/erc6551/interfaces/IERC6551Registry.sol";
import {DeployDelMundoWallet} from "./DeployDelMundoWallet.s.sol";

contract DeployAll is Script {
    address public admin;
    address public delMundoAddr;
    address public delMundoTraitAddr;
    address public raywardAddr;
    address public raycognitionAddr;
    address public wallet;
    address public registryAddr;
    uint256 public chainId;
    address public rayWallet;
    address public diamondcut;
    address public diamondLoupe;
    address public ownership;
    uint256 deployerPrivateKey;

    constructor(){
        deployerPrivateKey = vm.envUint("ANVIL_DEPLOYER_PRIVATE_KEY");
        admin = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
    }

    function deploy() external {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        admin = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        run();
    }

    function run() public {
        // 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is admin and address [0] from anvil

        vm.startBroadcast(deployerPrivateKey);

        DeployDelMundo delMundo = new DeployDelMundo();
        delMundoAddr = delMundo.deploy(admin);
        console.log("DELMUNDO_ADDRESS=", delMundoAddr);

        DeployDelMundoTrait delMundoTrait = new DeployDelMundoTrait();
        delMundoTraitAddr = delMundoTrait.deploy(admin);
        console.log("DELMUNDOTRAIT_ADDRESS=", delMundoTraitAddr);

        DeployRayward rayward = new DeployRayward();
        raywardAddr = rayward.deploy(admin);
        console.log("RAYWARD_ADDRESS=", raywardAddr);

        DeployRaycognition raycognition = new DeployRaycognition();
        raycognitionAddr = raycognition.deploy(admin);
        console.log("RAYCOGNITION_ADDRESS=", raycognitionAddr);

        DeployDelMundoWallet deployWallet = new DeployDelMundoWallet();
        wallet = deployWallet.run();
        console.log("DELMUNDOWALLET_ADDRESS=", wallet);

        DeployTokenBoundRegistry registry = new DeployTokenBoundRegistry();
        registryAddr = registry.run();
        console.log("REGISTRY_ADDRESS=", registryAddr);
        chainId = vm.envUint("CHAINID");
        rayWallet = IERC6551Registry(registryAddr).account(wallet, 0, chainId, delMundoAddr, 0);
        console.log("RAYWALLET_ADDRESS=", rayWallet);

        DeployDiamondFacets coreFacets = new DeployDiamondFacets();
        (diamondcut, diamondLoupe, ownership) = coreFacets.run();

//        DeployClimetaDiamond deployClimeta = new DeployClimetaDiamond();
//        deployClimeta.run();

        vm.stopBroadcast();
    }
}
