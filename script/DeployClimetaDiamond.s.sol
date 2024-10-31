// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {ClimetaDiamond, DiamondArgs} from "../src/ClimetaDiamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {DiamondInit} from "../src/utils/DiamondInit.sol";
import {Raycognition} from "../src/token/Raycognition.sol";
import "../src/utils/DiamondHelper.sol";

contract DeployClimetaDiamond is Script, DiamondHelper {
    uint256 deployerPrivateKey;
    address deployerAddress;

    constructor(){
        deployerPrivateKey = vm.envUint("ANVIL_DEPLOYER_PRIVATE_KEY");
        deployerAddress = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
    }

    function deploy() external {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        run();
    }

    function run() public returns (address) {

        //read env variables and choose EOA for transaction signing
        address _delMundoAddress = vm.envAddress("DELMUNDO_ADDRESS");
        address _raywardAddress = vm.envAddress("RAYWARD_ADDRESS");
        address _raycognitionAddress = vm.envAddress("RAYCOGNITION_ADDRESS");
        address _raywalletAddress = vm.envAddress("RAYWALLET_ADDRESS");
        address _delmundowalletAddress = vm.envAddress("DELMUNDOWALLET_ADDRESS");
        address _registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        address _ops = vm.envAddress("OPS_TREASURY_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        //deploy facets and init contract
        DiamondCutFacet dCutF = new DiamondCutFacet();
        DiamondLoupeFacet dLoupeF = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();

        DiamondInit diamondInit = new DiamondInit();

        // diamond arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: deployerAddress,
            init: address(diamondInit),
            initCalldata: abi.encodeWithSignature("init(address,address,address,address,address,address,address)", _delMundoAddress, _raywardAddress, _raycognitionAddress, _delmundowalletAddress, _raywalletAddress, _registryAddress, _ops)
        });

        // FacetCut array which contains the three standard facets to be added
        FacetCut[] memory cut = new FacetCut[](3);

        cut[0] = FacetCut ({
            facetAddress: address(dCutF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondCutFacet")
        });

        cut[1] = (
            FacetCut({
            facetAddress: address(dLoupeF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DiamondLoupeFacet")
        })
        );

        cut[2] = (
            FacetCut({
            facetAddress: address(ownerF),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("OwnershipFacet")
        })
        );

        // deploy diamond
        ClimetaDiamond diamond = new ClimetaDiamond(cut, _args);

        // Add diamond address where it needs to be
        // Raycognition has Climeta as a minter for granting raywards
        Raycognition(_raycognitionAddress).grantMinter(address(diamond));
        console.log("CLIMETA_ADDRESS=", address(diamond));
        vm.stopBroadcast();

        return (address(diamond));
    }
}
