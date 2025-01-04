// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../src/facets/TraitFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/ITraits.sol";

contract DeployTraitFacet is Script, DiamondHelper {
    function run(address climetaAddress) public {
        //deploy facets and init contract
        TraitFacet traitFacet = new TraitFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        // FacetCut array which contains the three standard facets to be added
        cut[0] = FacetCut ({
            facetAddress: address(traitFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("TraitFacet")
        });

        IDiamondCut climeta = IDiamondCut(climetaAddress);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(ITraits).interfaceId, true);
    }
}
