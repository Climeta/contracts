// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/token/Rayputation.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployRayputation} from "../../script/DeployRayputation.s.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract RayputationTest is Test {
    Rayputation rayputation;
    address private admin;
    uint256 constant DECIMALS = 9;

    function setUp() public {
        admin = makeAddr("admin");
        DeployRayputation rayputationDeployer = new DeployRayputation();
        rayputation = Rayputation(payable(rayputationDeployer.run(admin)));
    }

    function test_RayputationDecimals() public {
        assertEq(rayputation.decimals(), DECIMALS);
    }

    function testFuzz_RayputationMint(uint256 amount, address luckyPerson) public {
        vm.assume(luckyPerson != admin);
        vm.prank(admin);
        rayputation.mint(luckyPerson, amount);
        assertEq(rayputation.balanceOf(luckyPerson), amount);
    }

    function test_NewMinterCanMint() public {
        address newMinter = makeAddr("newMinter");
        vm.prank(admin);
        rayputation.grantMinter(newMinter);
        assertEq(rayputation.hasRole(rayputation.MINTER_ROLE(), newMinter), true);
        address user1 = makeAddr("user1");
        vm.prank(newMinter);
        rayputation.mint(user1, 100);
        assertEq(rayputation.balanceOf(user1), 100);
        assertEq(rayputation.totalSupply(), 100);
    }

    function testFuzz_GrantMinterAccessControl(address newMinter) public {
        vm.assume(newMinter != admin);
        vm.startPrank(newMinter);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, newMinter, rayputation.MINTER_ADMIN_ROLE()));
        rayputation.grantMinter(newMinter);
        vm.stopPrank();
    }

    function test_NameSymbol() public {
        assertEq(rayputation.name(), "Rayputation");
        assertEq(rayputation.symbol(), "RAYPUTATION");
    }

    function testFuzz_RevokeMinterAccessControl(address naughtyOne) public {
        vm.assume(naughtyOne != admin);
        address newAdmin = makeAddr("newAdmin");
        vm.startPrank(admin);
        rayputation.grantMinter(newAdmin);
        vm.stopPrank();

        vm.startPrank(naughtyOne);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, naughtyOne, rayputation.MINTER_ADMIN_ROLE()));
        rayputation.revokeMinter(newAdmin);
        vm.stopPrank();
    }

    function testFuzz_MintAccessControl(address minter, uint256 amount) public {
        vm.assume(minter != admin);
        vm.startPrank(minter);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, minter, rayputation.MINTER_ROLE()));
        rayputation.mint(makeAddr("1"), amount);
        vm.stopPrank();
    }

    function test_CantMoveTokens() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        rayputation.mint(user1, 100);
        rayputation.mint(user2, 200);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(Rayputation.Rayputation__NotMinter.selector);
        rayputation.transfer(user2, 50);

        vm.prank(user2);
        vm.expectRevert(Rayputation.Rayputation__NotMinter.selector);
        rayputation.transfer(user1, 50);
    }

    function test_CantMoveTokensEvenAsAdmin() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        rayputation.mint(user1, 100);
        rayputation.mint(user2, 200);
        vm.stopPrank();

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector,address(admin),0, 50));
        rayputation.transferFrom(user1, user2, 50);
    }

    function test_CantMoveTokensViaApproveOrDirect() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        rayputation.mint(user1, 100);
        rayputation.mint(user2, 200);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(Rayputation.Rayputation__NotMinter.selector);
        rayputation.transfer(user2, 50);

        vm.prank(user1);
        rayputation.approve(user2, 50);

        assertEq(rayputation.allowance(user1, user2), 50);

        vm.prank(user2);
        vm.expectRevert(Rayputation.Rayputation__NotMinter.selector);
        rayputation.transferFrom(user1, user2, 50);
    }




}