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
    function run(address _owner, address _delMundoAddress, address _raywardAddress, address _raycognitionAddress, address _raywalletAddress, address _delmundowalletAddress, address _registryAddress, address _ops) public returns (address) {
        //deploy facets and init contract
        DiamondCutFacet dCutF = new DiamondCutFacet();
        DiamondLoupeFacet dLoupeF = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();

        DiamondInit diamondInit = new DiamondInit();

        // diamond arguments
        DiamondArgs memory _args = DiamondArgs({
            owner: _owner,
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
        bytes4[] memory selectors = generateSelectors("DiamondLoupeFacet");
        // Add the supportsInterface(bytes4) selector
        bytes4[] memory fullSelectors = new bytes4[](selectors.length + 1);
        for (uint256 i; i < selectors.length; i++) {
            fullSelectors[i] = selectors[i];
        }
        fullSelectors[selectors.length] = bytes4(keccak256("supportsInterface(bytes4)"));
        cut[1] = (
            FacetCut({
            facetAddress: address(dLoupeF),
            action: FacetCutAction.Add,
            functionSelectors: fullSelectors
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
        console.log("CLIMETA_ADDRESS=", address(diamond));
        return (address(diamond));
    }
}
