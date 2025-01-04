// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import {MarketplaceFacet} from "../src/facets/MarketplaceFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IMarketplace.sol";

contract DeployMarketplaceFacet is Script, DiamondHelper {
    function run(address climetaAddress) public  {
        MarketplaceFacet marketplaceFacet = new MarketplaceFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut ({
            facetAddress: address(marketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MarketplaceFacet")
        });

        IDiamondCut climeta = IDiamondCut(climetaAddress);

        bytes memory data = abi.encodeWithSignature("init()");
        climeta.diamondCut(cut, address(marketplaceFacet), data);
        climeta.diamondSetInterface(type(IMarketplace).interfaceId, true);
    }
}
