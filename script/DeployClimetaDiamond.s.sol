// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {ClimetaDiamond, DiamondArgs} from "../src/ClimetaDiamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {DiamondInit} from "../src/utils/DiamondInit.sol";
import "../src/utils/DiamondHelper.sol";

contract DeployClimetaDiamond is Script, DiamondHelper {
    function run() external {

        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        address _delMundoAddress = vm.envAddress("DELMUNDO_ADDRESS");

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
            initCalldata: abi.encodeWithSignature("init(address)", _delMundoAddress)
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
        console.log("CLIMETA_ADDRESS=", address(diamond));
        vm.stopBroadcast();
    }
}
