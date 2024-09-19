// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/utils/DiamondInit.sol";
//import "../test/HelperContract.sol";


contract DeployClimetaDiamond is Script {
    function run() external {

        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.envAddress("PUBLIC_KEY");

        vm.startBroadcast(deployerPrivateKey);

        //deploy facets and init contract
        DiamondCutFacet dCutF = new DiamondCutFacet();
        DiamondLoupeFacet dLoupeF = new DiamondLoupeFacet();
        OwnershipFacet ownerF = new OwnershipFacet();

        DiamondInit diamondInit = new DiamondInit();


//        // diamod arguments
//        DiamondArgs memory _args = DiamondArgs({
//            owner: deployerAddress,
//            init: address(diamondInit),
//            initCalldata: abi.encodeWithSignature("init()")
//        });
//
//        // FacetCut array which contains the three standard facets to be added
//        FacetCut[] memory cut = new FacetCut[](3);
//
//        cut[0] = FacetCut ({
//            facetAddress: address(dCutF),
//            action: IDiamond.FacetCutAction.Add,
//            functionSelectors: generateSelectors("DiamondCutFacet")
//        });
//
//        cut[1] = (
//            FacetCut({
//            facetAddress: address(dLoupeF),
//            action: FacetCutAction.Add,
//            functionSelectors: generateSelectors("DiamondLoupeFacet")
//        })
//        );
//
//        cut[2] = (
//            FacetCut({
//            facetAddress: address(ownerF),
//            action: FacetCutAction.Add,
//            functionSelectors: generateSelectors("OwnershipFacet")
//        })
//        );
//
//
//        // deploy diamond
//        Diamond diamond = new Diamond(cut, _args);
//

        diamondInit.init(deployerAddress,deployerAddress,deployerAddress,deployerAddress,deployerAddress,deployerAddress,deployerAddress);

        vm.stopBroadcast();
    }
}
