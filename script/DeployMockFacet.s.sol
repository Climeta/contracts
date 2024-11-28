// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../test/mocks/MockFacetV1.sol";
import "../test/mocks/IMockFacetV1.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";

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
        MockFacet mockFacet = new MockFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        // FacetCut array which contains the three standard facets to be added
        cut[0] = FacetCut ({
            facetAddress: address(mockFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("test/mocks/MockFacetV1.sol:MockFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climeta = IDiamondCut(climetaAddress);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IMockFacet).interfaceId, true);

        vm.stopBroadcast();
    }
}
