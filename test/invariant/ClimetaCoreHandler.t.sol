// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console2} from "forge-std/Test.sol";
import {ClimetaCore} from "../../src/ClimetaCore.sol";

contract ClimetaCoreHandler is Test {
    ClimetaCore climetaCore;
    address admin;

    address[] public proposals;
    address[] public users;
    address internal currentUser;

    constructor(ClimetaCore _climetaCore, address _admin) {
        climetaCore = _climetaCore;
        admin = _admin;
        users.push(makeAddr("user1"));
        users.push(makeAddr("user2"));
        users.push(makeAddr("user3"));
        users.push(makeAddr("user4"));
        users.push(makeAddr("user5"));

    }

    function castVote(uint256 userSeed, uint256 propId) public {
        bound(propId, 0, proposals.length-1);
        currentUser = users[bound(userSeed, 0, users.length-1)];
        vm.startPrank(currentUser);
        climetaCore.castVote(propId);
        vm.stopPrank();
    }

    function addProposalToVotingRound(uint256 _proposalId, address _admin) public {
        vm.startPrank(_admin);
        climetaCore.addProposalToVotingRound(_proposalId);
        vm.stopPrank();
    }

    function endVotingRound(address _admin) public {
        vm.startPrank(_admin);
        climetaCore.endVotingRound();
        vm.stopPrank();
    }



}
