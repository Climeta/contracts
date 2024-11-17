// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {DeployClimetaDiamond} from "../../script/DeployClimetaDiamond.s.sol";
import {DeployAdminFacet} from "../../script/DeployAdminFacet.s.sol";
import {DeployDonationFacet} from "../../script/DeployDonationFacet.s.sol";
import {DeployVotingFacet} from "../../script/DeployVotingFacet.s.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {IDonation} from "../../src/interfaces/IDonation.sol";
import { LibDiamond } from "../../src/lib/LibDiamond.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract ClimetaDonationTest is Test {
    //    Authorization auth;
    address ops;
    address admin;
    address climetaAddr;
    ERC20Mock stablecoin1;
    ERC20Mock stablecoin2;
    ERC20Mock stablecoin3;
    IDonation climeta;
    IAdmin climetaAdmin;
    address brand1;
    address brand2;
    address brand3;
    address brand4;

    function setUp() public {
        DeployAll preDeployer = new DeployAll();
        preDeployer.run();
        DeployClimetaDiamond climetaDeployer = new DeployClimetaDiamond();
        climetaAddr = climetaDeployer.run();
        DeployAdminFacet adminDeployer = new DeployAdminFacet();
        adminDeployer.run();
        DeployDonationFacet donationDeployer = new DeployDonationFacet();
        donationDeployer.run();
        DeployVotingFacet votingDeployer = new DeployVotingFacet();
        votingDeployer.run();

        admin = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
        ops = IAdmin(climetaAddr).getOpsTreasuryAddress();
        vm.prank(admin);

        stablecoin1 = new ERC20Mock();
        stablecoin2 = new ERC20Mock();
        stablecoin3 = new ERC20Mock();

        climeta = IDonation(climetaAddr);
        climetaAdmin = IAdmin(climetaAddr);
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
        stablecoin1.approve(climetaAddr, 100);
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

        vm.startPrank(admin);
        climetaAdmin.addAllowedToken(address(stablecoin1));
        climetaAdmin.addAllowedToken(address(stablecoin2));
        climetaAdmin.addAllowedToken(address(stablecoin3));
        climeta.setMinimumERC20Donation(address(stablecoin1), 1_000);
        climeta.setMinimumERC20Donation(address(stablecoin2), 2_000);
        climeta.setMinimumERC20Donation(address(stablecoin3), 3_000);
        vm.stopPrank();

        vm.startPrank(brand1);
        stablecoin1.approve(climetaAddr, 100_000);
        stablecoin2.approve(climetaAddr, 200_000);
        stablecoin3.approve(climetaAddr, 300_000);

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
        assertEq(IDonation(climeta).donationFacetVersion(), "1.0");

        vm.startPrank(admin);
        climetaAdmin.addAllowedToken(address(stablecoin1));
        climetaAdmin.addAllowedToken(address(stablecoin2));
        climetaAdmin.addAllowedToken(address(stablecoin3));
        climeta.setMinimumEthDonation(1 ether);
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
        stablecoin1.approve(climetaAddr, 100);
        stablecoin2.approve(climetaAddr, 200);
        stablecoin3.approve(climetaAddr, 300);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin1), 100);
        climeta.donateToken(address(stablecoin1), 100);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin2), 200);
        climeta.donateToken(address(stablecoin2), 200);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand2, address(stablecoin3), 300);
        climeta.donateToken(address(stablecoin3), 300);
        vm.stopPrank();

        vm.startPrank(brand3);
        stablecoin1.approve(climetaAddr, 10);
        stablecoin2.approve(climetaAddr, 20);
        stablecoin3.approve(climetaAddr, 30);
        vm.expectEmit();
        emit IDonation.Climeta__ERC20Donation(brand3, address(stablecoin1), 10);
        climeta.donateToken(address(stablecoin1), 10);
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
        climeta.donate{value: 10 ether}();
        vm.stopPrank();
        assertEq(climeta.getTotalDonations(), 15 ether);


    }
}

