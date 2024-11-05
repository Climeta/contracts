// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ClimetaCore} from "../../src/ClimetaCore.sol";
import "../../src/Authorization.sol";
import "../../src/RayWallet.sol";
import "../../src/token/Rayward.sol";
import "../../src/token/DelMundo.sol";
import {DeployRayWallet} from "../../script/DeployRayWallet.s.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.s.sol";
import {DeployRayward} from "../../script/DeployRayward.s.sol";
import {DeployTokenBoundRegistry} from "../../script/DeployTokenBoundRegistry.s.sol";
import {ClimetaCoreHandler} from "./ClimetaCoreHandler.t.sol";

contract ClimetaCoreInvariant is Test {

    Authorization auth;
    address payable ops;
    address admin;
    RayWallet rayWallet;
    DelMundo delMundo;
    ERC6551Registry registry;
    ClimetaCore climetaCore;
    Rayward rayward;
    ClimetaCoreHandler handler;

    uint256 constant VOTE_REWARD = 100000000000;            // 100 raywards
    uint256 constant VOTE_MULTIPLIER = 1;
    uint256 constant REWARDPOOL_INITIAL = 10000000000000;   // 10000 raywards

    function setUp() public {
        admin = makeAddr("admin");
        ops = payable(makeAddr("ops"));

        DeployRayWallet rayWalletDeployer = new DeployRayWallet();
        rayWallet = RayWallet(payable(rayWalletDeployer.run()));

        DeployRayward raywardDeployer = new DeployRayward();
        rayward = Rayward(payable(raywardDeployer.deploy(admin)));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.deploy(admin));

        DeployTokenBoundRegistry registryDeployer = new DeployTokenBoundRegistry();
        registry = ERC6551Registry(registryDeployer.run());

        address raysWallet = registry.account(address(rayWallet), 0, block.chainid, address(delMundo), 0);
        // Setup the handler and the functions to call
    }

    function statefulFuzz_Voting() public {
    }

}
