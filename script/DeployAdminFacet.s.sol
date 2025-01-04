// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/facets/AdminFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DeployAdminFacet is Script, DiamondHelper {

    function run(address _climeta) external {
        AdminFacet adminFacet = new AdminFacet();
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(adminFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("AdminFacet")
        });
        IDiamondCut climeta = IDiamondCut(_climeta);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IAdmin).interfaceId, true);
    }

}
