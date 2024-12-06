// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import {MockFacet as MockFacetV1} from "../test/mocks/MockFacetV1.sol";
import {MockFacet as MockFacetV2} from "../test/mocks/MockFacetV2.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";
import {IMockFacet as IMockFacetV1} from "../test/mocks/IMockFacetV1.sol";
import {IMockFacet as IMockFacetV2} from "../test/mocks/IMockFacetV2.sol";

contract DeployMockFacet is Script, DiamondHelper {

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

    function run() public {
        //read env variables and choose EOA for transaction signing
        vm.startBroadcast(deployerPrivateKey);

        //deploy facets and init contract
        MockFacetV2 upgradedMockFacet = new MockFacetV2();
        FacetCut[] memory cut = new FacetCut[](1);

        // FacetCut array which contains the original facet to remove
        cut[0] = FacetCut ({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: generateSelectors("test/mocks/MockFacetV1.sol:MockFacet")
        });

        cut[1] = FacetCut ({
            facetAddress: address(upgradedMockFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("test/mocks/MockFacetV2.sol:MockFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climeta = IDiamondCut(climetaAddress);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IMockFacetV1).interfaceId, false);
        climeta.diamondSetInterface(type(IMockFacetV2).interfaceId, true);

        vm.stopBroadcast();
    }
}
