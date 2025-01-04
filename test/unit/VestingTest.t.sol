 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/token/Rayward.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
 import {ClimetaVestingWallet} from "../../src/utils/ClimetaVestingWallet.sol";
 import {DeployRayward} from "../../script/DeployRayward.s.sol";
 import {DeployVestingWallet} from "../../script/DeployVestingWallet.s.sol";

contract VestingTest is Test {
    Rayward rayward;
    ClimetaVestingWallet wallet1;
    address wallet1address;
    ClimetaVestingWallet wallet2;
    ClimetaVestingWallet wallet3;
    address private admin;
    address investor1;
    address investor2;
    address investor3;
    uint256 constant DECIMALS = 18;

    function setUp() public {
        admin = makeAddr("admin");
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        investor3 = makeAddr("investor3");
        DeployRayward raywardDeployer = new DeployRayward();
        rayward = Rayward(payable(raywardDeployer.run(admin)));
        vm.prank(admin);
        rayward.mint(admin, 10_000_000 );

        console.log("Admin now has ", rayward.balanceOf(admin));
    }

    function test_Create12MonthCliff12MonthVestWallet() public {
        uint64 months12 = 365 * 24 * 60 * 60;
        uint64 day1 = 24 * 60 * 60;

        DeployVestingWallet walletDeployer = new DeployVestingWallet();
        uint64 start = uint64(block.timestamp + months12);

        wallet1address = walletDeployer.deploy(address(rayward), payable(investor1), start, months12 );
        wallet1 = ClimetaVestingWallet(payable(wallet1address));

        vm.prank(admin);
        rayward.transfer(wallet1address, 1_000_000);

        vm.prank(investor1);
        vm.assertEq( wallet1.releasable(address(rayward)), 0);
        vm.assertEq( wallet1.released(address(rayward)), 0);

        vm.warp(block.timestamp + months12);
        vm.assertEq( wallet1.releasable(address(rayward)), 0);

        vm.warp(block.timestamp + day1);
        vm.assertEq( wallet1.releasable(address(rayward)), 2739);

        vm.prank(investor1);
        wallet1.getMyRaywards();

        vm.assertEq(rayward.balanceOf(investor1), 2739);
        vm.assertEq( wallet1.releasable(address(rayward)), 0);

        vm.warp(block.timestamp + months12);
        vm.prank(investor1);
        wallet1.getMyRaywards();

        vm.assertEq( wallet1.releasable(address(rayward)), 0);
        vm.assertEq( wallet1.released(address(rayward)), 1_000_000);
        vm.assertEq(rayward.balanceOf(investor1), 1_000_000);
        vm.assertEq(rayward.balanceOf(wallet1address), 0);
    }

}