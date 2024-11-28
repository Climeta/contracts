// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {DeployClimetaDiamond} from "../../script/DeployClimetaDiamond.s.sol";
import {DeployMockFacet} from "../../script/DeployMockFacet.s.sol";
import {DeployAdminFacet} from "../../script/DeployAdminFacet.s.sol";
import {IMockFacet} from "../mocks/IMockFacetV1.sol";
import {MockFacet as MockFacetV1} from "../mocks/MockFacetV1.sol";
import {MockFacet as MockFacetV2} from "../mocks/MockFacetV2.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IDiamondLoupe} from "../../src/interfaces/IDiamondLoupe.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import { LibDiamond } from "../../src/lib/LibDiamond.sol";
import "../../src/utils/DiamondHelper.sol";
import "../../src/interfaces/IDiamondCut.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract DiamondTest is Test, DiamondHelper {
    address ops;
    address admin;
    address climeta;
    address mockv1;
    address mockv2;
    address mockv3;

    function setUp() public {
        DeployAll preDeployer = new DeployAll();
        preDeployer.run();
        DeployClimetaDiamond climetaDeployer = new DeployClimetaDiamond();
        climeta = climetaDeployer.run();
        DeployMockFacet mockDeployer = new DeployMockFacet();
        mockDeployer.run();
        admin = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
    }

    function test_SupportsInterfaces() public {
        assertTrue(IERC165(climeta).supportsInterface(type(IMockFacet).interfaceId));
    }

    function test_Upgrade() public {
        assertEq(MockFacetV1(climeta).mockFacetVersion(), "1.0");

        vm.prank(admin);
        MockFacetV1(climeta).setMockValueMapping1(1, 100);
        assertEq(MockFacetV1(climeta).getMockValueMapping1(1), 100);

        vm.expectRevert();
        MockFacetV2(climeta).getMockValueMapping2(1);

        Facet[] memory facets = IDiamondLoupe(climeta).facets();
        // Should be 4 facets - Cut, Loupe, Ownership and Mock.
        assertEq(facets.length, 4);
        assertEq(IDiamondLoupe(climeta).facetAddresses()[0], facets[0].facetAddress);
        assertEq(IDiamondLoupe(climeta).facetAddresses()[1], facets[1].facetAddress);
        assertEq(IDiamondLoupe(climeta).facetAddresses()[2], facets[2].facetAddress);
        assertEq(IDiamondLoupe(climeta).facetAddresses()[3], facets[3].facetAddress);
        // MockFacet is 4th entry in array and should have 3 functions, 1 get, 1 set and version.
        assertEq(facets[3].functionSelectors.length, 3);
        bytes4[] memory selectors = IDiamondLoupe(climeta).facetFunctionSelectors(facets[3].facetAddress);
        assertEq(selectors.length, 3);

        assertEq(IDiamondLoupe(climeta).facetAddress(facets[3].functionSelectors[0]), facets[3].facetAddress);
        assertEq(IDiamondLoupe(climeta).facetAddress(facets[3].functionSelectors[1]), facets[3].facetAddress);
        assertEq(IDiamondLoupe(climeta).facetAddress(facets[3].functionSelectors[2]), facets[3].facetAddress);

        ////////////// FACET UPGRADE //////////////////////
        vm.startPrank(admin);
        MockFacetV2 mockFacet = new MockFacetV2();
        FacetCut[] memory cut = new FacetCut[](2);

        // FacetCut array which contains the original facet to remove
        cut[0] = FacetCut ({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: generateSelectors("test/mocks/MockFacetV1.sol:MockFacet")
        });

        cut[1] = FacetCut ({
            facetAddress: address(mockFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("test/mocks/MockFacetV2.sol:MockFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climetaDiamond = IDiamondCut(climetaAddress);
        climetaDiamond.diamondCut(cut, address(0), "0x");
        vm.stopPrank();

        facets = IDiamondLoupe(climeta).facets();
        // Should be 4 facets - Cut, Loupe, Ownership and Mock still.
        assertEq(facets.length, 4);
        // MockFacet is 4th entry in array and should have 3 functions, 2 get, 2 set and version.
        assertEq(facets[3].functionSelectors.length, 5);


        assertEq(MockFacetV1(climeta).mockFacetVersion(), "2.0");
        assertEq(MockFacetV2(climeta).mockFacetVersion(), "2.0");

        assertEq(MockFacetV2(climeta).getMockValueMapping1(1), 100);
        vm.startPrank(admin);
        MockFacetV2(climeta).setMockValueMapping2(1, 150);
        MockFacetV2(climeta).setMockValueMapping1(1, 2000);

        assertEq(MockFacetV2(climeta).getMockValueMapping2(1), 150);
        assertEq(MockFacetV2(climeta).getMockValueMapping1(1), 2000);




    }
}

