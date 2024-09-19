// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";

contract DeployDiamondFacets is Script {

    function run() external returns (address, address, address) {
        DiamondCutFacet diamondCutFacet = new DiamondCutFacet();
        DiamondLoupeFacet diamondLoupFacet = new DiamondLoupeFacet();
        OwnershipFacet ownershipFacet = new OwnershipFacet();
        return (address(diamondCutFacet), address(diamondLoupFacet), address(ownershipFacet));
    }
}