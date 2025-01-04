// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../test/mocks/MockFacetV1.sol";
import "../test/mocks/IMockFacetV1.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DeployMockFacet is Script, DiamondHelper {
    function run(address climetaAddress) public {


    }
}
