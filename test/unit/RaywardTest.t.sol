// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/token/Rayward.sol";
import {DeployRayward} from "../../script/DeployRayward.sol";

contract RaywardTest is Test {
    Rayward rayward;
    address private admin;

    function setUp() public {
        admin = makeAddr("admin");
        DeployRayward raywardDeployer = new DeployRayward();
        rayward = Rayward(payable(raywardDeployer.run(admin)));
        address current = address(this);
        vm.startPrank(address(raywardDeployer));
        rayward.grantRole(rayward.MINTER_ROLE(), current);
        vm.stopPrank();

    }

    function test_Decimals() public {
        assertEq(rayward.decimals(), 18);
    }

    function test_CantMint() public {
        vm.expectRevert();
        vm.prank(makeAddr("1"));
        rayward.mint(makeAddr("1"), 1000);
    }

    function test_Mint() public {

        rayward.mint(makeAddr("1"), 1000);
        assertEq(rayward.balanceOf(makeAddr("1")), 1000);
    }
}