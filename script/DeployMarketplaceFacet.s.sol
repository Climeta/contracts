// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import {MarketplaceFacet} from "../src/facets/MarketplaceFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IMarketplace.sol";

contract DeployMareketplaceFacet is Script, DiamondHelper {
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
        vm.startBroadcast(deployerPrivateKey);

        MarketplaceFacet marketplaceFacet = new MarketplaceFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut ({
            facetAddress: address(marketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MarketplaceFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climeta = IDiamondCut(climetaAddress);

        bytes memory data = abi.encodeWithSignature("init()");
        climeta.diamondCut(cut, address(marketplaceFacet), data);
        climeta.diamondSetInterface(type(IMarketplace).interfaceId, true);

        vm.stopBroadcast();
    }
}
