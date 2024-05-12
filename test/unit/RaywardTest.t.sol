// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/token/Rayward.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployRayward} from "../../script/DeployRayward.sol";

contract RaywardTest is Test {
    Rayward rayward;
    address private admin;
    uint256 constant DECIMALS = 18;

    function setUp() public {
        admin = makeAddr("admin");
        DeployRayward raywardDeployer = new DeployRayward();
        rayward = Rayward(payable(raywardDeployer.run(admin)));
    }

    function testFuzz_GrantMinterAccessControl(address newMinter) public {
        vm.assume(newMinter != admin);
        vm.startPrank(newMinter);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, newMinter, rayward.ADMIN_MINTER_ROLE()));
        rayward.grantMinter(newMinter);
        vm.stopPrank();
    }

    function testFuzz_RevokeMinterAccessControl(address naughtyOne) public {
        vm.assume(naughtyOne != admin);
        address newAdmin = makeAddr("newAdmin");
        vm.startPrank(admin);
        rayward.grantMinter(newAdmin);
        vm.stopPrank();

        vm.startPrank(naughtyOne);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, naughtyOne, rayward.ADMIN_MINTER_ROLE()));
        rayward.revokeMinter(newAdmin);
        vm.stopPrank();
    }

    function testFuzz_MintAccessControl(address minter, uint256 amount) public {
        vm.assume(minter != admin);
        vm.startPrank(minter);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, minter, rayward.MINTER_ROLE()));
        rayward.mint(makeAddr("1"), amount);
        vm.stopPrank();
    }

    function test_Decimals() public {
        assertEq(rayward.decimals(), DECIMALS);
    }

    function testFuzz_Mint(uint256 amount) public {
        vm.assume(amount < rayward.MAX_SUPPLY());
        vm.prank(admin);
        rayward.mint(makeAddr("1"), amount);
        assertEq(rayward.balanceOf(makeAddr("1")), amount);
    }

    function test_Cap() public {
        uint256 max = rayward.MAX_SUPPLY();
        vm.startPrank(admin);
        rayward.mint(makeAddr("1"), max);
        assertEq(rayward.balanceOf(makeAddr("1")), max);
        vm.expectRevert();
        rayward.mint(makeAddr("2"), 1);
    }

    function test_MovingRaywards() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        rayward.mint(user1, 100);
        rayward.mint(user2, 200);
        vm.stopPrank();

        vm.prank(user1);
        rayward.transfer(user2, 50);
        assertEq(rayward.balanceOf(user1), 50);
        assertEq(rayward.balanceOf(user2), 250);

    }

}