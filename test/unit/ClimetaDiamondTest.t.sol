// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import "../../src/RayWallet.sol";
import "../../src/token/Rayward.sol";
import "../../src/token/DelMundo.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {DeployClimetaDiamond} from "../../script/DeployClimetaDiamond.s.sol";
import {DeployAdminFacet} from "../../script/DeployAdminFacet.s.sol";
import {DeployDonationFacet} from "../../script/DeployDonationFacet.s.sol";
import {DeployVotingFacet} from "../../script/DeployVotingFacet.s.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {IDonation} from "../../src/interfaces/IDonation.sol";
import {IVoting} from "../../src/interfaces/IVoting.sol";
import { LibDiamond } from "../../src/lib/LibDiamond.sol";

contract ClimetaDiamondTest is Test {
    uint256 constant VOTING_REWARD = 600;
    uint256 constant VOTE_RAYCOGNITION = 100;
    uint256 constant VOTING_ROUND_REWARD = 60_000;
    uint256 constant VOTE_MULTIPLIER = 1;
    uint256 constant REWARDPOOL_INITIAL = 10_000_000_000_000;   // 10,000 raywards

    //    Authorization auth;
    address ops;
    address admin;
    address climeta;


    function setUp() public {
        DeployAll preDeployer = new DeployAll();
        preDeployer.run();
        DeployClimetaDiamond climetaDeployer = new DeployClimetaDiamond();
        climeta = climetaDeployer.run();
        DeployAdminFacet adminDeployer = new DeployAdminFacet();
        adminDeployer.run();
        DeployDonationFacet donationDeployer = new DeployDonationFacet();
        donationDeployer.run();
        DeployVotingFacet votingDeployer = new DeployVotingFacet();
        votingDeployer.run();

        admin = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
        ops = IAdmin(climeta).getOpsTreasuryAddress();
        vm.prank(admin);
        IAdmin(climeta).setVoteRaycognition(VOTE_RAYCOGNITION);
    }

    function test_Version() public {
        assertEq(IAdmin(climeta).adminFacetVersion(), "1.0");
        assertEq(IDonation(climeta).donationFacetVersion(), "1.0");
        assertEq(IVoting(climeta).votingFacetVersion(), "1.0");
    }

    function test_Statics() public {
        uint256 reward = IAdmin(climeta).getVoteReward();
        console.log("Reward ", reward);
        assertEq(reward, VOTING_REWARD);
        vm.prank(admin);
        IAdmin(climeta).setVoteReward(VOTING_REWARD * 2);
        assertEq(IAdmin(climeta).getVoteReward(), VOTING_REWARD * 2);

        vm.prank(admin);
        IAdmin(climeta).setVotingRoundReward(VOTING_ROUND_REWARD * 2);
        assertEq(IAdmin(climeta).getVotingRoundReward(), VOTING_ROUND_REWARD * 2);

        assertEq(IAdmin(climeta).getVoteRaycognition(), VOTE_RAYCOGNITION);
        vm.prank(admin);
        IAdmin(climeta).setVoteRaycognition(VOTE_RAYCOGNITION*2);
        assertEq(IAdmin(climeta).getVoteRaycognition(), VOTE_RAYCOGNITION*2);
    }


    function test_ChangeOwner() public {
        address newAdmin1 = makeAddr("new-admin1");
        address newAdmin2 = makeAddr("new-admin2");
        vm.expectRevert();
        IOwnership(climeta).transferOwnership(newAdmin1);

        vm.prank(admin);
        IOwnership(climeta).transferOwnership(newAdmin1);
        assertEq(IOwnership(climeta).owner(), newAdmin1);

        vm.expectRevert();
        IOwnership(climeta).transferOwnership(newAdmin2);

        vm.prank(newAdmin1);
        IOwnership(climeta).transferOwnership(newAdmin2);
        assertEq(IOwnership(climeta).owner(), newAdmin2);
    }


    function test_TransferReverts() public {
        deal(address(this), 2 ether);
        vm.expectRevert();
        climeta.call{value: 1 ether}("");
    }

    function test_AddBeneficiary() public {
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        assertEq(IVoting(climeta).isBeneficiary(beneficiary1), false);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), false);

        vm.expectRevert();
        IVoting(climeta).approveBeneficiary(beneficiary1, true);

        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary1, true);
        vm.prank(admin);
        IVoting(climeta).approveBeneficiary(beneficiary1, true);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary1), true);

        // Add second beneficiary
        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary2, true);
        vm.prank(admin);
        IVoting(climeta).approveBeneficiary(beneficiary2, true);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), true);

        // Remove second beneficiary
        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary2, false);
        vm.prank(admin);
        IVoting(climeta).approveBeneficiary(beneficiary2, false);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), false);

        // Add second back in
        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary2, true);
        vm.prank(admin);
        IVoting(climeta).approveBeneficiary(beneficiary2, true);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), true);

        // Remove both and add third time
        vm.startPrank(admin);
        IVoting(climeta).approveBeneficiary(beneficiary1, false);
        IVoting(climeta).approveBeneficiary(beneficiary2, false);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary1), false);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), false);

        // Add both in again
        IVoting(climeta).approveBeneficiary(beneficiary1, true);
        IVoting(climeta).approveBeneficiary(beneficiary2, true);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary1), true);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), true);
    }


    function test_AddUpdateProposal() public {
        assertEq(IVoting(climeta).getProposals(IVoting(climeta).getVotingRound()).length, 0);

        address notBeneficiary = makeAddr("notBeneficiary");
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        vm.startPrank(admin);
        IVoting(climeta).approveBeneficiary(beneficiary1, true);
        IVoting(climeta).approveBeneficiary(beneficiary2, true);
        vm.stopPrank();

        // Test only admin can add
        vm.prank(notBeneficiary);
        vm.expectRevert();
        IVoting(climeta).addProposalByOwner(beneficiary1, "proposal-uri");
        vm.prank(beneficiary1);
        vm.expectRevert();
        IVoting(climeta).addProposalByOwner(beneficiary1, "proposal-uri");

        vm.prank(notBeneficiary);
        vm.expectRevert();
        IVoting(climeta).addProposal("proposal-uri");

        vm.prank(beneficiary1);
        vm.expectEmit();
        emit IVoting.Climeta__NewProposal(beneficiary1, 1);
        uint256 proposalId1 = IVoting(climeta).addProposal("proposal-uri1");
        vm.prank(admin);
        vm.expectEmit();
        emit IVoting.Climeta__NewProposal(beneficiary2, 2);
        uint256 proposalId2 = IVoting(climeta).addProposalByOwner(beneficiary2, "proposal-uri2");

        address bene;
        string memory uri;
        (bene, uri) = IVoting(climeta).getProposal(proposalId1);
        assertEq(bene, beneficiary1);
        assertEq(uri, "proposal-uri1");
        (bene, uri) = IVoting(climeta).getProposal(proposalId2);
        assertEq(bene, beneficiary2);
        assertEq(uri, "proposal-uri2");

        // Test updates
        vm.prank(notBeneficiary);
        vm.expectRevert(IVoting.Climeta__NotProposalOwner.selector);
        IVoting(climeta).updateProposalMetadata(1, "proposal-uri1a");

        vm.prank(beneficiary2);
        vm.expectRevert(IVoting.Climeta__NotProposalOwner.selector);
        IVoting(climeta).updateProposalMetadata(proposalId1, "proposal-uri1a");

        vm.prank(beneficiary1);
        IVoting(climeta).updateProposalMetadata(proposalId1, "proposal1-uri1a");
        (bene, uri) = IVoting(climeta).getProposal(proposalId1);
        assertEq(uri, "proposal1-uri1a");

        vm.prank(beneficiary2);
        IVoting(climeta).updateProposalMetadata(proposalId2, "proposal1-uri2a");
        (bene, uri) = IVoting(climeta).getProposal(proposalId2);
        assertEq(uri, "proposal1-uri2a");

        // Add to voting round and ensure cant update any more
        vm.prank(admin);
        IVoting(climeta).addProposalToVotingRound(proposalId2);

        assertEq( IVoting(climeta).getProposals( IVoting(climeta).getVotingRound() ).length, 1);

        vm.prank(beneficiary2);
        vm.expectRevert(IVoting.Climeta__AlreadyInRound.selector);
        IVoting(climeta).updateProposalMetadata(proposalId2, "proposal1-uri2a");
    }

    function test_VotingRounds() public {
        IVoting climetaCore = IVoting(climeta);
        uint256 votingRound = climetaCore.getVotingRound();
        assertEq(votingRound, 1);

        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        vm.startPrank(admin);
        climetaCore.approveBeneficiary(beneficiary1, true);
        climetaCore.approveBeneficiary(beneficiary2, true);
        uint256 prop1 = climetaCore.addProposalByOwner(beneficiary1, "proposal1-uri1");
        uint256 prop2 = climetaCore.addProposalByOwner(beneficiary2, "proposal1-uri2");
        vm.stopPrank();

        // Test initial conditionals
        vm.prank(makeAddr("notAdmin"));
        vm.expectRevert(LibDiamond.Climeta__NotAdmin.selector);
        climetaCore.addProposalToVotingRound(prop1);

        vm.startPrank(admin);
        vm.expectRevert(IVoting.Climeta__NoProposal.selector);
        climetaCore.addProposalToVotingRound(prop1 - 1);
        vm.expectRevert(IVoting.Climeta__NoProposal.selector);
        climetaCore.addProposalToVotingRound(prop2 + 1);

        // Add the 2 in to current round
        vm.expectEmit();
        emit IVoting.Climeta__ProposalIncluded(votingRound, prop1);
        climetaCore.addProposalToVotingRound(prop1);
        vm.expectEmit();
        emit IVoting.Climeta__ProposalIncluded(votingRound, prop2);
        climetaCore.addProposalToVotingRound(prop2);
        vm.stopPrank();

        assertEq(climetaCore.getProposals(votingRound).length, 2);

        // Remove tests
        vm.prank(makeAddr("notAdmin"));
        vm.expectRevert(LibDiamond.Climeta__NotAdmin.selector);
        climetaCore.removeProposalFromVotingRound(prop1);

        vm.startPrank(admin);
        vm.expectRevert(IVoting.Climeta__ProposalNotInRound.selector);
        climetaCore.removeProposalFromVotingRound(prop1 - 1);
        vm.expectRevert(IVoting.Climeta__ProposalNotInRound.selector);
        climetaCore.removeProposalFromVotingRound(prop2 + 1);

        vm.expectEmit();
        emit IVoting.Climeta__ProposalExcluded(votingRound, prop1);
        climetaCore.removeProposalFromVotingRound(prop1);
        assertEq(climetaCore.getProposals(votingRound).length, 1);

        vm.expectEmit();
        emit IVoting.Climeta__ProposalExcluded(votingRound, prop2);
        climetaCore.removeProposalFromVotingRound(prop2);
        assertEq(climetaCore.getProposals(votingRound).length, 0);
    }
//
//
//    function testCastVote() public {
//        // Set up vote!
//        address beneficiary1 = makeAddr("beneficiary1");
//        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
//        climetaCore.addProposal(beneficiary1, "proposal1-uri");
//        climetaCore.addProposalToVotingRound(1);
//
//        address beneficiary2 = makeAddr("beneficiary2");
//        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
//        climetaCore.addProposal(beneficiary2, "proposal1-uri");
//        climetaCore.addProposalToVotingRound(2);
//
//        address user1 = makeAddr("user1");
//        address user2 = makeAddr("user2");
//        address user3 = makeAddr("user3");
//
//        // Ensure non members can't vote
//        vm.startPrank(user1);
//        vm.expectRevert(ClimetaCore.ClimetaCore__NotRayWallet.selector);
//        climetaCore.castVote(1);
//        vm.stopPrank();
//
//        vm.startPrank(address(this));
//        vm.expectRevert();
//        climetaCore.castVote(1);
//        vm.stopPrank();
//        assertEq(climetaCore.getVotesForProposal(1).length, 0);
//        assertEq(climetaCore.getVotesForProposal(2).length, 0);
//
//        // Mint NFTs to members directly and create the erc6551 raywallets
//        vm.startPrank(admin);
//        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
//        delMundo.safeMint(user1, 1, "uri-1");
//        delMundo.safeMint(user2, 2, "uri-2");
//        delMundo.safeMint(user3, 3, "uri-3");
//        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
//        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);
//        address account2 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 2);
//        address account3 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 3);
//
//        // mint some raywards to ray for rewards and then approve.
//        rayward.mint(account0, REWARDPOOL_INITIAL);
//        string memory approveAbi = "approve(address,uint256)";
//        bytes memory approveCalldata = abi.encodeWithSignature(approveAbi, address(climetaCore), REWARDPOOL_INITIAL);
//        RayWallet(payable(account0)).executeCall(address(rayward), 0, approveCalldata);
//        vm.stopPrank();
//
//        // Check no users have any raywards yet
//        assertEq(rayward.balanceOf(account0), REWARDPOOL_INITIAL);
//        assertEq(rayward.balanceOf(account1), 0);
//        assertEq(rayward.balanceOf(account2), 0);
//        assertEq(rayward.balanceOf(account3), 0);
//
//        // check that the wallets are correctly assigned to the right users
//        assertEq(RayWallet(payable(account1)).owner(), user1);
//        assertEq(RayWallet(payable(account2)).owner(), user2);
//        assertEq(RayWallet(payable(account3)).owner(), user3);
//
//        console.log("About to try a vote as a member");
//
//        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
//        string memory voteAbi = "castVote(uint256)";
//        bytes memory voteFor3Data = abi.encodeWithSignature(voteAbi, 3);
//        vm.startPrank(user1);
//        vm.expectRevert();
//        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor3Data);
//        vm.stopPrank();
//
//        console.log("Made it past castvote ray check!");
//
//        bytes memory voteFor1Data = abi.encodeWithSignature(voteAbi, 1);
//        bytes memory voteFor2Data = abi.encodeWithSignature(voteAbi, 2);
//        vm.startPrank(user1);
//        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor1Data);
//        vm.stopPrank();
//
//        // Ensure the right NFT is marked as having voted.
//        assertFalse(climetaCore.hasVoted(0));
//        assertTrue(climetaCore.hasVoted(1));
//        assertFalse(climetaCore.hasVoted(2));
//        assertFalse(climetaCore.hasVoted(3));
//        assertFalse(climetaCore.hasVoted(300));
//
//        assertEq(climetaCore.getVotesForProposal(1).length, 1);
//        assertEq(climetaCore.getVotesForProposal(2).length, 0);
//
//        vm.startPrank(user1);
//        vm.expectRevert(ClimetaCore.ClimetaCore__AlreadyVoted.selector);
//        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor1Data);
//
//        vm.expectRevert(ClimetaCore.ClimetaCore__AlreadyVoted.selector);
//        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor2Data);
//        vm.stopPrank();
//
//        console.log("Checked User1 cannot vote again");
//
//        // Now user2 votes via his NFT
//        vm.startPrank(user2);
//        vm.expectEmit();
//        emit ClimetaCore__Vote(2, 2);
//        RayWallet(payable(account2)).executeCall(address(climetaCore), 0, voteFor2Data);
//        vm.stopPrank();
//        assertEq(climetaCore.getVotesForProposal(1).length, 1);
//        assertEq(climetaCore.getVotesForProposal(2).length, 1);
//        console.log("User2 voted with NFT 1");
//
//        vm.startPrank(user3);
//        vm.expectEmit();
//        emit ClimetaCore__Vote(3, 2);
//        RayWallet(payable(account3)).executeCall(address(climetaCore), 0, voteFor2Data);
//        vm.stopPrank();
//        assertEq(climetaCore.getVotesForProposal(1).length, 1);
//        assertEq(climetaCore.getVotesForProposal(2).length, 2);
//        console.log("User3 voted with NFT 2");
//
//        assertEq(rayward.balanceOf(account0), REWARDPOOL_INITIAL - (VOTE_REWARD*3));
//        assertEq(rayward.balanceOf(account1), VOTE_REWARD);
//        assertEq(rayward.balanceOf(account2), VOTE_REWARD);
//        assertEq(rayward.balanceOf(account3), VOTE_REWARD);
//    }
//
//    function test_EndVotingRound() public {
//        // Set up vote!
//
//        // Get donations in
//        address brand1 = makeAddr("brand1");
//        address brand2 = makeAddr("brand2");
//        deal(brand1, 10 ether);
//        deal(brand2, 10 ether);
//
//        vm.startPrank(brand1);
//        address(auth).call{value: 5 ether}("");
//        vm.stopPrank();
//        vm.startPrank(brand2);
//        address(auth).call{value: 10 ether}("");
//        vm.stopPrank();
//
//        vm.startPrank(admin);
//        auth.approveDonation(brand1, 5 ether);
//        auth.approveDonation(brand2, 10 ether);
//        vm.stopPrank();
//
//        // test that donation amounts are correct
//        assertEq(climetaCore.getTotalDonatedFunds(), 13.5 ether);
//        assertEq(climetaCore.getTotalDonationsByAddress(brand1), 4.5 ether);
//        assertEq(climetaCore.getTotalDonationsByAddress(brand2), 9 ether);
//
//        address beneficiary1 = makeAddr("beneficiary1");
//        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
//        climetaCore.addProposal(beneficiary1, "proposal1-uri");
//        climetaCore.addProposalToVotingRound(1);
//
//        address beneficiary2 = makeAddr("beneficiary2");
//        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
//        climetaCore.addProposal(beneficiary2, "proposal1-uri");
//        climetaCore.addProposalToVotingRound(2);
//
//        address user1 = makeAddr("user1");
//        address user2 = makeAddr("user2");
//
//        // Mint NFTs to members directly and create the erc6551 raywallets
//        vm.startPrank(admin);
//        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
//        delMundo.safeMint(user1, 1, "uri-1");
//        delMundo.safeMint(user2, 2, "uri-2");
//        address account0 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 0);
//        address account1 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 1);
//        address account2 = registry.createAccount(address(rayWallet), 0, block.chainid, address(delMundo), 2);
//
//        // mint some raywards to ray for rewards and then approve.
//        rayward.mint(account0, REWARDPOOL_INITIAL);
//        string memory approveAbi = "approve(address,uint256)";
//        bytes memory approveCalldata = abi.encodeWithSignature(approveAbi, address(climetaCore), REWARDPOOL_INITIAL);
//        RayWallet(payable(account0)).executeCall(address(rayward), 0, approveCalldata);
//        vm.stopPrank();
//
//        // Check can't end vote if no votes
//        vm.expectRevert(ClimetaCore.ClimetaCore__NoVotes.selector);
//        climetaCore.endVotingRound();
//
//        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
//        string memory voteAbi = "castVote(uint256)";
//        bytes memory voteFor1Data = abi.encodeWithSignature(voteAbi, 1);
//        bytes memory voteFor2Data = abi.encodeWithSignature(voteAbi, 2);
//
//        vm.startPrank(user1);
//        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor1Data);
//        vm.stopPrank();
//
//        vm.startPrank(user2);
//        RayWallet(payable(account2)).executeCall(address(climetaCore), 0, voteFor1Data);
//        vm.stopPrank();
//
//        assertEq(climetaCore.getVotesForProposal(1).length, 2);
//        assertEq(climetaCore.getVotesForProposal(2).length, 0);
//
//        // check starting balance will be 90% of the donated 15
//        assertEq(address(climetaCore).balance, 13.5 ether);
//
//        climetaCore.endVotingRound();
//
//        // test the voting round has been incremented
//        assertEq(climetaCore.s_votingRound(), 2);
//        // balance should still be 15.5 ether as nothing has been pushed or withdrawn yet
//        assertEq(address(climetaCore).balance, 13.5 ether);
//
//        // ensure only owner can get funds
//        assertEq(climetaCore.getWithdrawAmount(beneficiary1),12825000000000000000);
//        assertEq(climetaCore.getWithdrawAmount(beneficiary2),675000000000000000);
//        assertEq(climetaCore.getWithdrawAmount(user1),0);
//
//        vm.prank(user1);
//        //vm.expectRevert(ClimetaCore.ClimetaCore__NoFundsToWithdraw.selector);
//        climetaCore.withdraw();
//
//        vm.startPrank(beneficiary1);
//        uint256 gas_start = gasleft();
//        climetaCore.withdraw();
//        uint256 gas_used = gas_start - gasleft();
//        assertEq(beneficiary1.balance, 12825000000000000000-(gas_used*tx.gasprice));
//        vm.stopPrank();
//
//        vm.startPrank(beneficiary2);
//        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
//        climetaCore.pushPayment(beneficiary2);
//        vm.stopPrank();
//
//        vm.prank(admin);
//        climetaCore.pushPayment(beneficiary2);
//
//        // Test balance is 10% of total split between the two beneficiaries and then rest to #1
//        assertEq(beneficiary2.balance, 675000000000000000);
//    }
}

//
//contract AttackSelfDestructMe {
//    ClimetaCore target;
//
//    constructor(ClimetaCore _target) payable {
//        target = _target;
//    }
//
//    function attack() external payable {
//        selfdestruct(payable(address(target)));
//    }
//}