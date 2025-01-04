// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {AdminFacet} from "../../src/facets/AdminFacet.sol";
import {DonationFacet} from "../../src/facets/DonationFacet.sol";
import {VotingFacet} from "../../src/facets/VotingFacet.sol";
import {MarketplaceFacet} from "../../src/facets/MarketplaceFacet.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IMarketplace} from "../../src/interfaces/IMarketplace.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {IDonation} from "../../src/interfaces/IDonation.sol";
import {IVoting} from "../../src/interfaces/IVoting.sol";
import { LibDiamond } from "../../src/lib/LibDiamond.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import "../../src/facets/AdminFacet.sol";
import "../../src/utils/DiamondHelper.sol";
import "../../src/interfaces/IDiamondCut.sol";

contract ClimetaDonationTest is Test, DiamondHelper {
    //    Authorization auth;
    address ops;
    address admin;
    ERC20Mock stablecoin1;
    ERC20Mock stablecoin2;
    ERC20Mock stablecoin3;
    IAdmin climetaAdmin;
    address brand1;
    address brand2;
    address brand3;
    address brand4;
    DeployAll.Addresses contracts;

    function setUp() public {
        ops = makeAddr("Ops");
        admin = makeAddr("Admin");

        vm.startPrank(admin);
        DeployAll deployer = new DeployAll();
        contracts = deployer.run(admin);

        // Deploy Facets
        AdminFacet adminFacet = new AdminFacet();
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(adminFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("AdminFacet")
        });
        IDiamondCut climeta = IDiamondCut(contracts.climeta);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IAdmin).interfaceId, true);

        DonationFacet donationFacet = new DonationFacet();
        cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(donationFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DonationFacet")
        });
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IDonation).interfaceId, true);

        VotingFacet votingFacet = new VotingFacet();
        cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(votingFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("VotingFacet")
        });
        bytes memory data = abi.encodeWithSignature("init()");
        climeta.diamondCut(cut, address(votingFacet), data);
        climeta.diamondSetInterface(type(IVoting).interfaceId, true);

        MarketplaceFacet marketplaceFacet = new MarketplaceFacet();
        cut = new FacetCut[](1);
        // remove supportsInterface
        cut[0] = FacetCut ({
            facetAddress: address(marketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MarketplaceFacet")
        });
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IMarketplace).interfaceId, true);

        stablecoin1 = new ERC20Mock();
        stablecoin2 = new ERC20Mock();
        stablecoin3 = new ERC20Mock();

        IAdmin(contracts.climeta).updateOpsTreasuryAddress(payable(ops));
        IAdmin(contracts.climeta).setWithdrawalOnly(false);
        vm.stopPrank();

        climetaAdmin = IAdmin(contracts.climeta);
        brand1 = makeAddr("brand1");
        brand2 = makeAddr("brand2");
        brand3 = makeAddr("brand3");
        brand4 = makeAddr("brand4");

        // Give brands some initial starting balances
        vm.deal(brand1, 100 ether);
        vm.deal(brand2, 100 ether);
        vm.deal(brand3, 100 ether);
        vm.deal(brand4, 100 ether);

        stablecoin1.mint(brand1, 1_000_000);
        stablecoin2.mint(brand1, 1_000_000);
        stablecoin3.mint(brand1, 1_000_000);
        stablecoin1.mint(brand2, 1_000_000);
        stablecoin2.mint(brand2, 1_000_000);
        stablecoin3.mint(brand2, 1_000_000);
        stablecoin1.mint(brand3, 1_000_000);
        stablecoin2.mint(brand3, 1_000_000);
        stablecoin3.mint(brand3, 1_000_000);
        stablecoin1.mint(brand4, 1_000_000);
        stablecoin2.mint(brand4, 1_000_000);
        stablecoin3.mint(brand4, 1_000_000);
    }

    function test_TokenApprovals() public {
        IDonation climeta = IDonation(contracts.climeta);

        vm.prank(brand1);
        vm.expectRevert(IDonation.Climeta__NotValueToken.selector);
        climeta.donateToken(address(stablecoin1), 100);

        vm.prank(admin);
        climetaAdmin.addAllowedToken(address(stablecoin1));

        // Will fail as no allowance granted
        vm.prank(brand1);
        vm.expectRevert();
        climeta.donateToken(address(stablecoin1), 100);

        vm.startPrank(brand1);
        stablecoin1.approve(contracts.climeta, 100);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand1, address(stablecoin1), 100);
        climeta.donateToken(address(stablecoin1), 100);
        vm.stopPrank();

        vm.startPrank(admin);
        climetaAdmin.addAllowedToken(address(stablecoin2));
        climetaAdmin.addAllowedToken(address(stablecoin3));

        assertEq(climetaAdmin.getAllowedTokens().length, 3);
        assertEq(climetaAdmin.getAllowedTokens()[0], address(stablecoin1));
        assertEq(climetaAdmin.getAllowedTokens()[1], address(stablecoin2));
        assertEq(climetaAdmin.getAllowedTokens()[2], address(stablecoin3));

        climetaAdmin.removeAllowedToken(address(stablecoin2));
        assertEq(climetaAdmin.getAllowedTokens().length, 2);
        assertEq(climetaAdmin.getAllowedTokens()[0], address(stablecoin1));
        assertEq(climetaAdmin.getAllowedTokens()[1], address(stablecoin3));

        vm.expectRevert(IAdmin.Climeta__ValueStillInContract.selector);
        climetaAdmin.removeAllowedToken(address(stablecoin1));

        climetaAdmin.addAllowedToken(address(stablecoin2));
        assertEq(climetaAdmin.getAllowedTokens()[0], address(stablecoin1));
        assertEq(climetaAdmin.getAllowedTokens()[1], address(stablecoin3));
        assertEq(climetaAdmin.getAllowedTokens()[2], address(stablecoin2));
        vm.stopPrank();
    }


    function test_MinimumDonations() public {
        IDonation climeta = IDonation(contracts.climeta);

        vm.startPrank(admin);
        climetaAdmin.addAllowedToken(address(stablecoin1));
        climetaAdmin.addAllowedToken(address(stablecoin2));
        climetaAdmin.addAllowedToken(address(stablecoin3));
        climeta.setMinimumERC20Donation(address(stablecoin1), 1_000);
        assertEq(climeta.getMinimumERC20Donation(address(stablecoin1)), 1_000);
        climeta.setMinimumERC20Donation(address(stablecoin2), 2_000);
        assertEq(climeta.getMinimumERC20Donation(address(stablecoin2)), 2_000);
        climeta.setMinimumERC20Donation(address(stablecoin3), 3_000);
        assertEq(climeta.getMinimumERC20Donation(address(stablecoin3)), 3_000);
        vm.stopPrank();

        vm.startPrank(brand1);
        stablecoin1.approve(contracts.climeta, 100_000);
        stablecoin2.approve(contracts.climeta, 200_000);
        stablecoin3.approve(contracts.climeta, 300_000);

        vm.expectRevert(IDonation.Climeta__DonationNotAboveThreshold.selector);
        climeta.donateToken(address(stablecoin1), 999);
        vm.expectRevert(IDonation.Climeta__DonationNotAboveThreshold.selector);
        climeta.donateToken(address(stablecoin1), 1);
        vm.expectRevert(IDonation.Climeta__DonationNotAboveThreshold.selector);
        climeta.donateToken(address(stablecoin2), 1999);
        vm.expectRevert(IDonation.Climeta__DonationNotAboveThreshold.selector);
        climeta.donateToken(address(stablecoin3), 2999);

        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand1, address(stablecoin1), 1_000);
        climeta.donateToken(address(stablecoin1), 1_000);

        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand1, address(stablecoin2), 2_000);
        climeta.donateToken(address(stablecoin2), 2_000);
        climeta.donateToken(address(stablecoin2), 2_000);
        assertEq(stablecoin2.balanceOf(brand1), 1_000_000 - 4_000);
        assertEq(stablecoin2.balanceOf(address(climeta)), 3_600);
        assertEq(stablecoin2.balanceOf(ops), 400);

        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand1, address(stablecoin3), 3_000);
        climeta.donateToken(address(stablecoin3), 3_000);
        vm.stopPrank();
    }



    function test_Donations() public {
        IDonation climeta = IDonation(contracts.climeta);
        assertEq(climeta.donationFacetVersion(), "1.0");

        vm.startPrank(admin);
        climetaAdmin.addAllowedToken(address(stablecoin1));
        climetaAdmin.addAllowedToken(address(stablecoin2));
        climetaAdmin.addAllowedToken(address(stablecoin3));
        climeta.setMinimumEthDonation(1 ether);
        assertEq(climeta.getMinimumEthDonation(), 1 ether);
        vm.stopPrank();

        vm.startPrank(brand1);
        vm.expectRevert(IDonation.Climeta__DonationNotAboveThreshold.selector);
        climeta.donate{value: 0.5 ether}();

        vm.expectEmit();
        emit IDonation.Climeta__Donation(brand1, 5 ether);
        climeta.donate{value: 5 ether}();
        vm.stopPrank();

        assertEq(address(climeta).balance + ops.balance, 5 ether);
        assertEq(ops.balance, 0.5 ether);
        assertEq(climeta.getTotalDonations(), 5 ether);
        assertEq(climeta.getDonations(brand1), 5 ether);
        assertEq(climeta.getDonations(brand2), 0);


        vm.startPrank(brand2);
        stablecoin1.approve(contracts.climeta, 100);
        stablecoin2.approve(contracts.climeta, 200);
        stablecoin3.approve(contracts.climeta, 300);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin1), 100);
        climeta.donateToken(address(stablecoin1), 100);
        assertEq(climeta.getTokenDonations(brand2, address(stablecoin1) ), 100);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin2), 200);
        climeta.donateToken(address(stablecoin2), 200);
        assertEq(climeta.getTokenDonations(brand2, address(stablecoin2) ), 200);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin3), 300);
        climeta.donateToken(address(stablecoin3), 300);
        assertEq(climeta.getTokenDonations(brand2, address(stablecoin3) ), 300);
        vm.stopPrank();

        vm.startPrank(brand3);
        stablecoin1.approve(contracts.climeta, 10);
        stablecoin2.approve(contracts.climeta, 20);
        stablecoin3.approve(contracts.climeta, 30);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand3, address(stablecoin1), 10);
        climeta.donateToken(address(stablecoin1), 10);
        assertEq(climeta.getTokenDonations(brand3, address(stablecoin1) ), 10);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand3, address(stablecoin2), 20);
        climeta.donateToken(address(stablecoin2), 20);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand3, address(stablecoin3), 30);
        climeta.donateToken(address(stablecoin3), 30);
        vm.stopPrank();

        assertEq(climeta.getTotalDonations(), 5 ether);
        assertEq(climeta.getTotalTokenDonations(address(stablecoin1)), 110);
        assertEq(climeta.getTotalTokenDonations(address(stablecoin2)), 220);
        assertEq(climeta.getTotalTokenDonations(address(stablecoin3)), 330);

        vm.startPrank(brand2);
        stablecoin1.approve(contracts.climeta, 100);
        stablecoin2.approve(contracts.climeta, 200);
        stablecoin3.approve(contracts.climeta, 300);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin1), 100);
        climeta.donateToken(address(stablecoin1), 100);
        assertEq(climeta.getTokenDonations(brand2, address(stablecoin1) ), 200);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin2), 200);
        climeta.donateToken(address(stablecoin2), 200);
        assertEq(climeta.getTokenDonations(brand2, address(stablecoin2)), 400);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin3), 300);
        climeta.donateToken(address(stablecoin3), 300);
        assertEq(climeta.getTokenDonations(brand2, address(stablecoin3) ), 600);
        vm.stopPrank();

        assertEq(climeta.getTotalTokenDonations(address(stablecoin1)), 210);
        assertEq(climeta.getTotalTokenDonations(address(stablecoin2)), 420);
        assertEq(climeta.getTotalTokenDonations(address(stablecoin3)), 630);


        vm.startPrank(brand2);
        climeta.donate{value: 10 ether}();
        vm.stopPrank();
        assertEq(climeta.getTotalDonations(), 15 ether);


    }
}

