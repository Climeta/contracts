// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {DeployClimetaDiamond} from "../../script/DeployClimetaDiamond.s.sol";
import {DeployMockFacet} from "../../script/DeployMockFacet.s.sol";
import {DeployAdminFacet} from "../../script/DeployAdminFacet.s.sol";
import {DeployDonationFacet} from "../../script/DeployDonationFacet.s.sol";
import {DeployVotingFacet} from "../../script/DeployVotingFacet.s.sol";
import {MockFacet as MockFacetV1} from "../mocks/MockFacetV1.sol";
import {MockFacet as MockFacetV2} from "../mocks/MockFacetV2.sol";
import {MockFacet as MockFacetV3} from "../mocks/MockFacetV3.sol";
import {IMockFacet as IMockFacetV1} from "../mocks/IMockFacetV1.sol";
import {IMockFacet as IMockFacetV2} from "../mocks/IMockFacetV2.sol";
import {IMockFacet as IMockFacetV3} from "../mocks/IMockFacetV3.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IDiamondLoupe} from "../../src/interfaces/IDiamondLoupe.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {IDonation} from "../../src/interfaces/IDonation.sol";
import {IVoting} from "../../src/interfaces/IVoting.sol";
import {ClimetaDiamond} from "../../src/ClimetaDiamond.sol";
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
        assertTrue(IERC165(climeta).supportsInterface(type(IMockFacetV1).interfaceId));

        assertFalse(IERC165(climeta).supportsInterface(type(IAdmin).interfaceId));
        DeployAdminFacet adminDeployer = new DeployAdminFacet();
        adminDeployer.run();
        assertTrue(IERC165(climeta).supportsInterface(type(IAdmin).interfaceId));

        assertFalse(IERC165(climeta).supportsInterface(type(IDonation).interfaceId));
        DeployDonationFacet donationDeployer = new DeployDonationFacet();
        donationDeployer.run();
        assertTrue(IERC165(climeta).supportsInterface(type(IDonation).interfaceId));

        assertFalse(IERC165(climeta).supportsInterface(type(IVoting).interfaceId));
        DeployVotingFacet votingDeployer = new DeployVotingFacet();
        votingDeployer.run();
        assertTrue(IERC165(climeta).supportsInterface(type(IVoting).interfaceId));
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


        assertTrue(IERC165(climeta).supportsInterface(type(IMockFacetV1).interfaceId));

        ////////////// FACET UPGRADE //////////////////////
        vm.startPrank(admin);
        MockFacetV2 mockFacetv2 = new MockFacetV2();
        FacetCut[] memory cut = new FacetCut[](2);

        // FacetCut array which contains the original facet to remove
        cut[0] = FacetCut ({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: generateSelectors("test/mocks/MockFacetV1.sol:MockFacet")
        });

        cut[1] = FacetCut ({
            facetAddress: address(mockFacetv2),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("test/mocks/MockFacetV2.sol:MockFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climetaDiamond = IDiamondCut(climetaAddress);
        climetaDiamond.diamondCut(cut, address(0), "0x");
        climetaDiamond.diamondSetInterface(type(IMockFacetV1).interfaceId, false);
        climetaDiamond.diamondSetInterface(type(IMockFacetV2).interfaceId, true);
        vm.stopPrank();

        assertFalse(IERC165(climeta).supportsInterface(type(IMockFacetV1).interfaceId));
        assertTrue(IERC165(climeta).supportsInterface(type(IMockFacetV2).interfaceId));

        facets = IDiamondLoupe(climeta).facets();
        // Should be 4 facets - Cut, Loupe, Ownership and Mock.
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
        vm.stopPrank();

        ////////////// FACET UPGRADE2 //////////////////////

        // Add a new facet inbetween upgrades test
        DeployAdminFacet adminDeployer = new DeployAdminFacet();
        adminDeployer.run();

        vm.startPrank(admin);
        MockFacetV3 mockFacetv3 = new MockFacetV3();
        FacetCut[] memory cut2 = new FacetCut[](2);

        // FacetCut array which contains the original facet to remove
        cut2[0] = FacetCut ({
            facetAddress: address(0),
            action: FacetCutAction.Remove,
            functionSelectors: generateSelectors("test/mocks/MockFacetV2.sol:MockFacet")
        });

        cut2[1] = FacetCut ({
            facetAddress: address(mockFacetv3),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("test/mocks/MockFacetV3.sol:MockFacet")
        });

        climetaDiamond.diamondCut(cut2, address(0), "0x");
        climetaDiamond.diamondSetInterface(type(IMockFacetV2).interfaceId, false);
        climetaDiamond.diamondSetInterface(type(IMockFacetV3).interfaceId, true);
        vm.stopPrank();




    }
}

