// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/token/Raycognition.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import {DeployRaycognition} from "../../script/DeployRaycognition.s.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";

contract RaycognitionTest is Test {
    Raycognition raycognition;
    address private admin;
    uint256 constant DECIMALS = 9;

    function setUp() public {
        admin = makeAddr("admin");
        DeployRaycognition raycognitionDeployer = new DeployRaycognition();
        raycognition = Raycognition(payable(raycognitionDeployer.deploy(admin)));
    }

    function test_RaycognitionDecimals() public view {
        assertEq(raycognition.decimals(), DECIMALS);
    }

    function testFuzz_RaycognitionMint(uint256 amount, address luckyPerson) public {
        vm.assume(luckyPerson != admin);
        vm.assume(luckyPerson != address(0));
        vm.prank(admin);
        raycognition.mint(luckyPerson, amount);
        assertEq(raycognition.balanceOf(luckyPerson), amount);
    }

    function test_NewMinterCanMint() public {
        address newMinter = makeAddr("newMinter");
        vm.prank(admin);
        raycognition.grantMinter(newMinter);
        assertEq(raycognition.hasRole(raycognition.MINTER_ROLE(), newMinter), true);
        address user1 = makeAddr("user1");
        vm.prank(newMinter);
        raycognition.mint(user1, 100);
        assertEq(raycognition.balanceOf(user1), 100);
        assertEq(raycognition.totalSupply(), 100);
    }

    function testFuzz_GrantMinterAccessControl(address newMinter) public {
        vm.assume(newMinter != admin);
        vm.startPrank(newMinter);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, newMinter, raycognition.MINTER_ROLE()));
        raycognition.grantMinter(newMinter);
        vm.stopPrank();
    }

    function test_NameSymbol() public view {
        assertEq(raycognition.name(), "Raycognition");
        assertEq(raycognition.symbol(), "RAYCOG");
    }

    function testFuzz_RevokeMinterAccessControl(address naughtyOne) public {
        vm.assume(naughtyOne != admin);
        address newAdmin = makeAddr("newAdmin");
        vm.startPrank(admin);
        raycognition.grantMinter(newAdmin);
        vm.stopPrank();

        vm.startPrank(naughtyOne);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, naughtyOne, raycognition.MINTER_ROLE()));
        raycognition.revokeMinter(newAdmin);
        vm.stopPrank();
    }

    function testFuzz_MintAccessControl(address minter, uint256 amount) public {
        vm.assume(minter != admin);
        vm.startPrank(minter);
        vm.expectRevert(abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, minter, raycognition.MINTER_ROLE()));
        raycognition.mint(makeAddr("1"), amount);
        vm.stopPrank();
    }

    function test_CantMoveTokens() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        raycognition.mint(user1, 100);
        raycognition.mint(user2, 200);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(Raycognition.Raycognition__NotMinter.selector);
        raycognition.transfer(user2, 50);

        vm.prank(user2);
        vm.expectRevert(Raycognition.Raycognition__NotMinter.selector);
        raycognition.transfer(user1, 50);
    }

    function test_CantMoveTokensEvenAsAdmin() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        raycognition.mint(user1, 100);
        raycognition.mint(user2, 200);
        vm.stopPrank();

        vm.prank(admin);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector,address(admin),0, 50));
        raycognition.transferFrom(user1, user2, 50);
    }

    function test_CantMoveTokensViaApproveOrDirect() public {
        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        vm.startPrank(admin);
        raycognition.mint(user1, 100);
        raycognition.mint(user2, 200);
        vm.stopPrank();

        vm.prank(user1);
        vm.expectRevert(Raycognition.Raycognition__NotMinter.selector);
        raycognition.transfer(user2, 50);

        vm.prank(user1);
        raycognition.approve(user2, 50);

        assertEq(raycognition.allowance(user1, user2), 50);

        vm.prank(user2);
        vm.expectRevert(Raycognition.Raycognition__NotMinter.selector);
        raycognition.transferFrom(user1, user2, 50);
    }




}