// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../lib/forge-std/src/Vm.sol";
import "../../src/Authorization.sol";
import "../../src/RayWallet.sol";
import "../../src/token/DelMundo.sol";
import "../../src/ERC6551Registry.sol";
import {DeployAuthorization} from "../../script/DeployAuthorization.s.sol";
import {DeployRayWallet} from "../../script/DeployRayWallet.s.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {DeployClimetaCore} from "../../script/DeployClimetaCore.s.sol";
import {DeployERC6551Registry} from "../../script/DeployERC6551Registry.s.sol";

contract AuthorizationTest is Test {
    Authorization auth;
    address payable ops;
    address admin;
    RayWallet rayWallet;
    DelMundo delMundo;
    ERC6551Registry registry;
    ClimetaCore climetaCore;

    function setUp() public {
        admin = makeAddr("admin");
        ops = payable(makeAddr("ops"));

        DeployRayWallet rayWalletDeployer = new DeployRayWallet();
        rayWallet = RayWallet(payable(rayWalletDeployer.run()));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));

        DeployERC6551Registry registryDeployer = new DeployERC6551Registry();
        registry = ERC6551Registry(registryDeployer.run());

        DeployClimetaCore climetaCoreDeployer = new DeployClimetaCore();
        climetaCore = ClimetaCore(payable(climetaCoreDeployer.run(admin, address(delMundo), address(delMundo), address(registry), address(rayWallet))));

        DeployAuthorization authorizationDeployer = new DeployAuthorization();
        auth = Authorization(payable(authorizationDeployer.run(admin, ops, payable(address(climetaCore)))));

        vm.prank(admin);
        climetaCore.updateAuthContract(address(auth));

        // Set this contract address up as a custodian
        address current = address(this);
        vm.startPrank(admin);
        auth.grantAdmin(current);
        vm.stopPrank();
    }

    function test_initialize() public view {
        assertEq(auth.version(), "1.0");
    }

    function test_GrantRevokeAdmins() public {
        address newAdmin = makeAddr("newAdmin");
        auth.grantAdmin(newAdmin);
        assert(auth.hasRole(auth.CUSTODIAN_ROLE(), newAdmin));
        assert(auth.hasRole(auth.ADMIN_CUSTODIAN_ROLE(), newAdmin));
        auth.revokeAdmin(newAdmin);
        assert(!auth.hasRole(auth.CUSTODIAN_ROLE(), newAdmin));
        assert(!auth.hasRole(auth.ADMIN_CUSTODIAN_ROLE(), newAdmin));
    }

    function test_updateOpsAddress() public {
        address newOps = makeAddr("newOps");
        auth.updateOpsAddress(payable(newOps));
        assertEq(auth.getOpsAddress(), newOps);
    }

    function test_updateOpsAddressIsSecure() public {
        address newOps = makeAddr("newOps");
        address user = makeAddr("randomUser");
        vm.prank(user);
        vm.expectRevert(Authorization.Authorization__NotAdmin.selector);
        auth.updateOpsAddress(payable(newOps));
    }

    function testFuzz_donation(uint256 amount) public payable {
        deal(address(this), amount);
        uint256 initialBalance = address(this).balance;
        vm.expectEmit();
        emit Authorization.donation(address(this), 1, amount);
        address(auth).call{value: amount}("");
        assertEq(address(this).balance, initialBalance - amount);
    }

    function test_approveDonation() public payable {
        deal(address(this), 2 ether);

        vm.expectEmit();
        emit Authorization.donation(address(this), 1, 1 ether);
        address(auth).call{value: 1 ether}("");

        uint256 s_opsBalance = ops.balance;
        uint256 s_votingBalance = address(climetaCore).balance;
        auth.approveDonation(address(this), 1 ether);

        assertEq(ops.balance - s_opsBalance, 1 ether / 10);
        assertEq(address(climetaCore).balance - s_votingBalance, 1 ether * 9 / 10);
    }

    function test_rejectDonation() public payable {
        deal(address(this), 2 ether);
        vm.expectEmit();
        emit Authorization.donation(address(this), 1, 1 ether);
        address(auth).call{value: 1 ether}("");
        uint256 s_opsBalance = ops.balance;
        uint256 s_votingBalance = address(climetaCore).balance;
        auth.rejectDonation(address(this), 1 ether);
        assertEq(ops.balance - s_opsBalance, 0);
        assertEq(address(climetaCore).balance - s_votingBalance, 0);
        (address[] memory addresses, uint256[] memory amounts) = auth.getAllPendingDonations();
        assertEq(addresses.length, 0);
    }

    // This test donates 1 eth and then tries all non 1 eth comvinations to make sure we don't approve.
    function test_approveNonExistentDonation(uint256 amount) public {
        vm.assume(amount != 1 ether);

        deal(address(this), 2 ether);
        vm.expectEmit();
        emit Authorization.donation(address(this), 1, 1 ether);
        address(auth).call{value: 1 ether}("");

        vm.recordLogs();
        auth.approveDonation(address(this), amount);
        VmSafe.Log[] memory logs = vm.getRecordedLogs();

        // Check logs to make sure no approval was made
        for (uint i = 0; i < logs.length; i++) {
            // Check that the event is not the one you're interested in
            assertNotEq(logs[i].topics[0], keccak256("approvedDonation(address,uint256,uint256)"));
        }
    }

    function testFuzz_rejectNonExistentDonation(uint256 amount) public {
        vm.assume(amount != 1 ether);
        deal(address(this), 2 ether);
        vm.expectEmit();
        emit Authorization.donation(address(this), 1, 1 ether);
        address(auth).call{value: 1 ether}("");

        vm.recordLogs();
        auth.rejectDonation(address(this), amount);
        VmSafe.Log[] memory logs = vm.getRecordedLogs();

        // Check logs to make sure no approval was made
        for (uint i = 0; i < logs.length; i++) {
            // Check that the event is not the one you're interested in
            assertNotEq(logs[i].topics[0], keccak256("rejectedDonation(address,uint256,uint256)"));
        }
    }

    function test_getAllPendingDonations() public {
        // Add in whole lot more
        address brand1 = makeAddr("brand1");
        address brand2 = makeAddr("brand2");
        address brand3 = makeAddr("brand3");
        deal(brand1, 20 ether);
        deal(brand2, 20 ether);
        deal(brand3, 20 ether);

        vm.startPrank(brand1);
        address(auth).call{value: 1 ether}("");
        address(auth).call{value: 1 ether}("");
        vm.stopPrank();

        vm.startPrank(brand2);
        address(auth).call{value: 2 ether}("");
        address(auth).call{value: 5 ether}("");
        vm.stopPrank();

        (address[] memory addresses, uint256[] memory amounts) = auth.getAllPendingDonations();
        assertEq(addresses.length, 4);
    }

    // TODO Invariant tests to make sure that any combination of donations and approvals/rejections is sound, even 2 donations from same address for same amount

}