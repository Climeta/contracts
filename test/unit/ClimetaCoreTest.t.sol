// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import "../../src/Authorization.sol";
import "../../src/RayWallet.sol";
import "../../src/token/Rayward.sol";
import "../../src/token/DelMundo.sol";
import "../../src/ERC6551Registry.sol";
import {DeployAuthorization} from "../../script/DeployAuthorization.sol";
import {DeployRayWallet} from "../../script/DeployRayWallet.sol";
import {DeployDelMundo} from "../../script/DeployDelMundo.sol";
import {DeployRayward} from "../../script/DeployRayward.sol";
import {DeployClimetaCore} from "../../script/DeployClimetaCore.sol";
import {DeployERC6551Registry} from "../../script/DeployERC6551Registry.sol";

contract ClimetaCoreTest is Test {
    Authorization auth;
    address payable ops;
    address admin;
    RayWallet rayWallet;
    DelMundo delMundo;
    ERC6551Registry registry;
    ClimetaCore climetaCore;
    Rayward rayward;

    uint256 constant VOTE_REWARD = 100;
    uint256 constant VOTE_MULTIPLIER = 1;
    uint256 constant REWARDPOOL_INITIAL = 10000;

    function setUp() public {
        admin = makeAddr("admin");
        ops = payable(makeAddr("ops"));

        DeployRayWallet rayWalletDeployer = new DeployRayWallet();
        rayWallet = RayWallet(payable(rayWalletDeployer.run()));

        DeployRayward raywardDeployer = new DeployRayward();
        rayward = Rayward(payable(raywardDeployer.run(admin)));

        DeployDelMundo delMundoDeployer = new DeployDelMundo();
        delMundo = DelMundo(delMundoDeployer.run(admin));

        DeployERC6551Registry registryDeployer = new DeployERC6551Registry();
        registry = ERC6551Registry(registryDeployer.run());

        address raysWallet = registry.account(address(rayWallet), block.chainid, address(delMundo), 0, 0);

        DeployClimetaCore climetaCoreDeployer = new DeployClimetaCore();
        climetaCore = ClimetaCore(payable(climetaCoreDeployer.run(admin, address(delMundo), address(rayward), address(registry), raysWallet)));

        DeployAuthorization authorizationDeployer = new DeployAuthorization();
        auth = Authorization(payable(authorizationDeployer.run(admin, ops, payable(address(climetaCore)))));

        address current = address(this);
        vm.startPrank(admin);
        climetaCore.updateAuthContract(address(auth));
        auth.grantAdmin(current);
        climetaCore.addAdmin(current);
        vm.stopPrank();
    }

    function test_Version() public {
        assertEq(climetaCore.version(), "1.0");
    }

    function test_VoteReward() public {
        assertEq(climetaCore.getVoteReward(), VOTE_REWARD);
    }

    function test_TransferReverts() public {
        deal(address(this), 2 ether);
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAuthContract.selector);
        address(climetaCore).call{value: 1 ether}("");

        // TODO - see what happens on contract destruct.
    }

    function test_IsAdmin() public {
        assertEq(climetaCore.isAdmin(address(this)), true);
        assertEq(climetaCore.isAdmin(makeAddr("Notadmnnin")), false);
    }

    function test_AddBeneficiary() public {
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        assertEq(climetaCore.isBeneficiary(beneficiary1), false);
        assertEq(climetaCore.isBeneficiary(beneficiary2), false);

        vm.expectRevert();
        climetaCore.addBeneficiary(beneficiary1, "", "beneficiary1-uri");

        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__NewBeneficiary(beneficiary1, "beneficiary1");
        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
        assertEq(climetaCore.isBeneficiary(beneficiary1), true);

        // Test that an update of a name to blank fails
        vm.expectRevert();
        climetaCore.addBeneficiary(beneficiary1, "", "beneficiary1-uri");

        // Add second beneficiary
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__NewBeneficiary(beneficiary2, "beneficiary2");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
        assertEq(climetaCore.isBeneficiary(beneficiary2), true);

        // Remove second beneficiary
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__RemovedBeneficiary(beneficiary2);
        climetaCore.removeBeneficiary(beneficiary2);
        assertEq(climetaCore.isBeneficiary(beneficiary2), false);

        // Remove second beneficiary again - should do nothing
        climetaCore.removeBeneficiary(beneficiary2);
        assertEq(climetaCore.isBeneficiary(beneficiary2), false);

        // Add second back in
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__NewBeneficiary(beneficiary2, "beneficiary2");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
        assertEq(climetaCore.isBeneficiary(beneficiary2), true);

        // Remove both and add third time
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__RemovedBeneficiary(beneficiary1);
        climetaCore.removeBeneficiary(beneficiary1);
        assertEq(climetaCore.isBeneficiary(beneficiary1), false);
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__RemovedBeneficiary(beneficiary2);
        climetaCore.removeBeneficiary(beneficiary2);
        assertEq(climetaCore.isBeneficiary(beneficiary2), false);

        // Add both in again
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__NewBeneficiary(beneficiary1, "beneficiary1");
        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
        assertEq(climetaCore.isBeneficiary(beneficiary1), true);
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__NewBeneficiary(beneficiary2, "beneficiary2");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
        assertEq(climetaCore.isBeneficiary(beneficiary2), true);
    }

    function test_AddUpdateProposal() public {
        // This should fail as there are no proposals
        vm.expectRevert();
        uint256 proposalId = climetaCore.s_proposalList(0);

        assertEq(climetaCore.getAllProposals().length, 0);

        address notBeneficiary = makeAddr("notBeneficiary");
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");

        // Test only admin can add
        vm.prank(notBeneficiary);
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
        climetaCore.addProposal(notBeneficiary, "proposal-uri");

        vm.prank(beneficiary1);
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
        climetaCore.addProposal(notBeneficiary, "proposal-uri");

        // test only approved beneficiaries can add proposals
        vm.expectRevert(ClimetaCore.ClimetaCore__NotApproved.selector);
        climetaCore.addProposal(notBeneficiary, "proposal-uri");

        // Expect block timestamp 1 and proposal id 1 for first ever proposal
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__NewProposal(beneficiary1, 1, 1);
        climetaCore.addProposal(beneficiary1, "proposal1-uri");
        assertEq(climetaCore.getProposal(1).beneficiaryAddress, beneficiary1);
        assertEq(climetaCore.getProposal(1).metadataURI, "proposal1-uri");
        assertEq(climetaCore.getAllProposals().length, 1);

        // Test updates
        vm.prank(notBeneficiary);
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
        climetaCore.updateProposal(1, "proposal-uri");
        assertEq(climetaCore.getAllProposals().length, 1);

        vm.prank(beneficiary1);
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
        climetaCore.updateProposal(1, "proposal-uri");

        // test update of non existent proposal fails
        vm.expectRevert(ClimetaCore.ClimetaCore__NoProposal.selector);
        climetaCore.updateProposal(2, "proposal1-uri2");

        climetaCore.updateProposal(1, "proposal1-uri2");
        assertEq(climetaCore.getProposal(1).metadataURI, "proposal1-uri2");
        climetaCore.updateProposal(1, "proposal1-uri3");
        assertEq(climetaCore.getProposal(1).metadataURI, "proposal1-uri3");

        // Expect block timestamp 1 and proposal id 1 for first ever proposal
        climetaCore.addProposal(beneficiary2, "proposal1-uri");
        assertEq(climetaCore.getProposal(2).beneficiaryAddress, beneficiary2);
        assertEq(climetaCore.getAllProposals().length, 2);
    }

    function test_VotingRounds() public {
        uint256 votingRound = climetaCore.s_votingRound();
        assertEq(votingRound, 1);

        address beneficiary1 = makeAddr("beneficiary1");
        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
        climetaCore.addProposal(beneficiary1, "proposal1-uri");

        address beneficiary2 = makeAddr("beneficiary2");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
        climetaCore.addProposal(beneficiary2, "proposal1-uri");

        // Test initial conditionals
        vm.prank(makeAddr("notAdmin"));
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
        climetaCore.addProposalToVotingRound(1);

        vm.expectRevert(ClimetaCore.ClimetaCore__NoProposal.selector);
        climetaCore.addProposalToVotingRound(0);
        vm.expectRevert(ClimetaCore.ClimetaCore__NoProposal.selector);
        climetaCore.addProposalToVotingRound(3);

        // Add the 2 in to current round
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__ProposalIncluded(1, 1);
        climetaCore.addProposalToVotingRound(1);
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__ProposalIncluded(1, 2);
        climetaCore.addProposalToVotingRound(2);

        assertEq(climetaCore.getProposalsThisRound().length, 2);
        assertEq(climetaCore.getProposal(1).votingRound, 1);
        assertEq(climetaCore.getProposal(2).votingRound, 1);

        // Remove tests
        vm.prank(makeAddr("notAdmin"));
        vm.expectRevert(ClimetaCore.ClimetaCore__NotAdmin.selector);
        climetaCore.removeProposalFromVotingRound(1);

        vm.expectRevert(ClimetaCore.ClimetaCore__ProposalNotInRound.selector);
        climetaCore.removeProposalFromVotingRound(0);
        vm.expectRevert(ClimetaCore.ClimetaCore__ProposalNotInRound.selector);
        climetaCore.removeProposalFromVotingRound(3);

        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__ProposalExcluded(1, 1);
        climetaCore.removeProposalFromVotingRound(1);
        assertEq(climetaCore.getProposalsThisRound().length, 1);
        assertEq(climetaCore.getProposal(1).votingRound, 0);
        assertEq(climetaCore.getProposal(2).votingRound, 1);
    }


    function testCastVote() public {
        // Set up vote!
        address beneficiary1 = makeAddr("beneficiary1");
        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
        climetaCore.addProposal(beneficiary1, "proposal1-uri");
        climetaCore.addProposalToVotingRound(1);

        address beneficiary2 = makeAddr("beneficiary2");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
        climetaCore.addProposal(beneficiary2, "proposal1-uri");
        climetaCore.addProposalToVotingRound(2);

        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");

        // Ensure non members can't vote
        vm.startPrank(user1);
        vm.expectRevert(ClimetaCore.ClimetaCore__NotRayWallet.selector);
        climetaCore.castVote(1);
        vm.stopPrank();

        vm.startPrank(address(this));
        vm.expectRevert();
        climetaCore.castVote(1);
        vm.stopPrank();
        assertEq(climetaCore.getVotesForProposal(1).length, 0);
        assertEq(climetaCore.getVotesForProposal(2).length, 0);

        // Mint NFTs to members directly and create the erc6551 raywallets
        vm.startPrank(admin);
        delMundo.safeMint(admin, "uri-ray"); // This is Ray himself
        delMundo.safeMint(user1, "uri-1");
        delMundo.safeMint(user2, "uri-2");
        delMundo.safeMint(user3, "uri-3");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");
        address account1 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 1, 0, "");
        address account2 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 2, 0, "");
        address account3 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 3, 0, "");

        // mint some raywards to ray for rewards and then approve.
        rayward.mint(account0, REWARDPOOL_INITIAL);
        string memory approveAbi = "approve(address,uint256)";
        bytes memory approveCalldata = abi.encodeWithSignature(approveAbi, address(climetaCore), REWARDPOOL_INITIAL);
        RayWallet(payable(account0)).executeCall(address(rayward), 0, approveCalldata);
        vm.stopPrank();

        // Check no users have any raywards yet
        assertEq(rayward.balanceOf(account0), REWARDPOOL_INITIAL);
        assertEq(rayward.balanceOf(account1), 0);
        assertEq(rayward.balanceOf(account2), 0);
        assertEq(rayward.balanceOf(account3), 0);

        // check that the wallets are correctly assigned to the right users
        assertEq(RayWallet(payable(account1)).owner(), user1);
        assertEq(RayWallet(payable(account2)).owner(), user2);
        assertEq(RayWallet(payable(account3)).owner(), user3);

        console.log("About to try a vote as a member");

        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
        string memory voteAbi = "castVote(uint256)";
        bytes memory voteFor3Data = abi.encodeWithSignature(voteAbi, 3);
        vm.startPrank(user1);
        vm.expectRevert();
        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor3Data);
        vm.stopPrank();

        console.log("Made it past castvote ray check!");

        bytes memory voteFor1Data = abi.encodeWithSignature(voteAbi, 1);
        bytes memory voteFor2Data = abi.encodeWithSignature(voteAbi, 2);
        vm.startPrank(user1);
        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor1Data);
        vm.stopPrank();

        // Ensure the right NFT is marked as having voted.
        assertFalse(climetaCore.hasVoted(0));
        assertTrue(climetaCore.hasVoted(1));
        assertFalse(climetaCore.hasVoted(2));
        assertFalse(climetaCore.hasVoted(3));
        assertFalse(climetaCore.hasVoted(300));

        assertEq(climetaCore.getVotesForProposal(1).length, 1);
        assertEq(climetaCore.getVotesForProposal(2).length, 0);

        vm.startPrank(user1);
        vm.expectRevert(ClimetaCore.ClimetaCore__AlreadyVoted.selector);
        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor1Data);

        vm.expectRevert(ClimetaCore.ClimetaCore__AlreadyVoted.selector);
        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor2Data);
        vm.stopPrank();

        console.log("Checked User1 cannot vote again");

        // Now user2 votes via his NFT
        vm.startPrank(user2);
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__Vote(2, 2);
        RayWallet(payable(account2)).executeCall(address(climetaCore), 0, voteFor2Data);
        vm.stopPrank();
        assertEq(climetaCore.getVotesForProposal(1).length, 1);
        assertEq(climetaCore.getVotesForProposal(2).length, 1);
        console.log("User2 voted with NFT 1");

        vm.startPrank(user3);
        vm.expectEmit();
        emit ClimetaCore.ClimetaCore__Vote(3, 2);
        RayWallet(payable(account3)).executeCall(address(climetaCore), 0, voteFor2Data);
        vm.stopPrank();
        assertEq(climetaCore.getVotesForProposal(1).length, 1);
        assertEq(climetaCore.getVotesForProposal(2).length, 2);
        console.log("User3 voted with NFT 2");

        assertEq(rayward.balanceOf(account0), REWARDPOOL_INITIAL - (VOTE_REWARD*3));
        assertEq(rayward.balanceOf(account1), VOTE_REWARD);
        assertEq(rayward.balanceOf(account2), VOTE_REWARD);
        assertEq(rayward.balanceOf(account3), VOTE_REWARD);
    }

    function testEndVotingRound() public {
        // Set up vote!

        // Get donations in
        address brand1 = makeAddr("brand1");
        address brand2 = makeAddr("brand2");
        deal(brand1, 10 ether);
        deal(brand2, 10 ether);

        vm.startPrank(brand1);
        address(auth).call{value: 5 ether}("");
        vm.stopPrank();
        vm.startPrank(brand2);
        address(auth).call{value: 10 ether}("");
        vm.stopPrank();

        vm.startPrank(admin);
        auth.approveDonation(brand1, 5 ether);
        auth.approveDonation(brand2, 10 ether);
        vm.stopPrank();

        address beneficiary1 = makeAddr("beneficiary1");
        climetaCore.addBeneficiary(beneficiary1, "beneficiary1", "beneficiary1-uri");
        climetaCore.addProposal(beneficiary1, "proposal1-uri");
        climetaCore.addProposalToVotingRound(1);

        address beneficiary2 = makeAddr("beneficiary2");
        climetaCore.addBeneficiary(beneficiary2, "beneficiary2", "beneficiary2-uri");
        climetaCore.addProposal(beneficiary2, "proposal1-uri");
        climetaCore.addProposalToVotingRound(2);

        address user1 = makeAddr("user1");
        address user2 = makeAddr("user2");

        // Mint NFTs to members directly and create the erc6551 raywallets
        vm.startPrank(admin);
        delMundo.safeMint(admin, "uri-ray"); // This is Ray himself
        delMundo.safeMint(user1, "uri-1");
        delMundo.safeMint(user2, "uri-2");
        address account0 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 0, 0, "");
        address account1 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 1, 0, "");
        address account2 = registry.createAccount(address(rayWallet), block.chainid, address(delMundo), 2, 0, "");

        // mint some raywards to ray for rewards and then approve.
        rayward.mint(account0, REWARDPOOL_INITIAL);
        string memory approveAbi = "approve(address,uint256)";
        bytes memory approveCalldata = abi.encodeWithSignature(approveAbi, address(climetaCore), REWARDPOOL_INITIAL);
        RayWallet(payable(account0)).executeCall(address(rayward), 0, approveCalldata);
        vm.stopPrank();

        // Check can't end vote if no votes
        vm.expectRevert(ClimetaCore.ClimetaCore__NoVotes.selector);
        climetaCore.endVotingRound();

        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
        string memory voteAbi = "castVote(uint256)";
        bytes memory voteFor1Data = abi.encodeWithSignature(voteAbi, 1);
        bytes memory voteFor2Data = abi.encodeWithSignature(voteAbi, 2);

        vm.startPrank(user1);
        RayWallet(payable(account1)).executeCall(address(climetaCore), 0, voteFor1Data);
        vm.stopPrank();

        vm.startPrank(user2);
        RayWallet(payable(account2)).executeCall(address(climetaCore), 0, voteFor1Data);
        vm.stopPrank();

        assertEq(climetaCore.getVotesForProposal(1).length, 2);
        assertEq(climetaCore.getVotesForProposal(2).length, 0);

        // check starting balance will be 90% of the donated 15
        assertEq(address(climetaCore).balance, 13.5 ether);

        climetaCore.endVotingRound();

        // test the voting round has been incremented and all the balance sent to charities
        assertEq(climetaCore.s_votingRound(), 2);
        assertEq(address(climetaCore).balance, 0);

        // Test balance is 10% of total split between the two beneficiaries and then rest to #1
        assertEq(beneficiary1.balance, 12825000000000000000);
        assertEq(beneficiary2.balance, 675000000000000000);
    }
}
