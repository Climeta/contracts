// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
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
import {DelMundo} from "../../src/token/DelMundo.sol";
import {Rayward} from "../../src/token/Rayward.sol";
import {Raycognition} from "../../src/token/Raycognition.sol";
import {ERC6551Registry} from "@tokenbound/erc6551/ERC6551Registry.sol";
import {RayWallet} from "../../src/RayWallet.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {VotesMockUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/mocks/VotesMockUpgradeable.sol";

contract ClimetaDiamondTest is Test {
    uint256 public constant VOTING_REWARD = 600;
    uint256 public constant VOTE_RAYCOGNITION = 100;
    uint256 public constant VOTING_ROUND_REWARD = 60_000;
    uint256 public constant VOTE_MULTIPLIER = 1;
    uint256 public constant REWARDPOOL_INITIAL = 10_000_000_000_000;   // 10,000 raywards

    //    Authorization auth;
    address ops;
    address admin;
    address climeta;
    address delMundoAddress;
    DelMundo delMundo;
    address raywardAddress;
    Rayward rayward;
    address raycognitionAddress;
    Raycognition raycognition;
    address registryAddress;
    ERC6551Registry registry;
    address rayWalletAddress;
    address delMundoWalletAddress;
    RayWallet rayWallet;
    ERC20Mock stablecoin1;
    ERC20Mock stablecoin2;

    struct Actors {
        address user1;
        address user2;
        address user3;
        address beneficiary1;
        address beneficiary2;
        address beneficiary3;
        address account0;
        address account1;
        address account2;
        address account3;
        address brand1;
        address brand2;
    }

    struct Proposals {
        uint256 prop1;
        bytes callVote1;
        uint256 prop2;
        bytes callVote2;
        uint256 prop3;
        bytes callVote3;
        uint256 prop4;
        bytes callVote4;
        uint256 prop5;
        bytes callVote5;
        uint256 prop6;
        bytes callVote6;
        uint256 prop7;
        bytes callVote7;
    }

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

        delMundoAddress = vm.envAddress("DELMUNDO_ADDRESS");
        delMundo = DelMundo(delMundoAddress);

        raywardAddress = vm.envAddress("RAYWARD_ADDRESS");
        rayward = Rayward(raywardAddress);

        registryAddress = vm.envAddress("REGISTRY_ADDRESS");
        registry = ERC6551Registry(registryAddress);

        rayWalletAddress = vm.envAddress("RAYWALLET_ADDRESS");
        rayWallet = RayWallet(payable(rayWalletAddress));

        raycognitionAddress = vm.envAddress("RAYCOGNITION_ADDRESS");
        raycognition = Raycognition(raycognitionAddress);

        delMundoWalletAddress = vm.envAddress("DELMUNDOWALLET_ADDRESS");

        admin = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
        ops = IAdmin(climeta).getOpsTreasuryAddress();
        vm.prank(admin);
        IAdmin(climeta).setVoteRaycognition(VOTE_RAYCOGNITION);

        stablecoin1 = new ERC20Mock();
        stablecoin2 = new ERC20Mock();
        vm.startPrank(admin);
        IAdmin(climeta).addAllowedToken(address(stablecoin1));
        IAdmin(climeta).addAllowedToken(address(stablecoin2));
        IAdmin(climeta).setVoteReward(VOTING_REWARD);
        IAdmin(climeta).setVotingRoundReward(VOTING_ROUND_REWARD);
        IAdmin(climeta).setWithdrawalOnly(false);
        vm.stopPrank();

    }

    function test_Version() public view {
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

        assertEq(IAdmin(climeta).getDelMundoAddress(), delMundoAddress);
        assertEq(IAdmin(climeta).getDelMundoTraitAddress(), vm.envAddress("DELMUNDOTRAIT_ADDRESS"));
        assertEq(IAdmin(climeta).getDelMundoWalletAddress(), vm.envAddress("DELMUNDOWALLET_ADDRESS"));
        assertEq(IAdmin(climeta).getRaywardAddress(), vm.envAddress("RAYWARD_ADDRESS"));
        assertEq(IAdmin(climeta).getRaycognitionAddress(), vm.envAddress("RAYCOGNITION_ADDRESS"));
        assertEq(IAdmin(climeta).getRegistryAddress(), vm.envAddress("REGISTRY_ADDRESS"));
        assertEq(IAdmin(climeta).getRayWalletAddress(), vm.envAddress("RAYWALLET_ADDRESS"));

        assertEq(IAdmin(climeta).getOpsTreasuryAddress(), vm.envAddress("OPS_TREASURY_ADDRESS"));
        address newOps = makeAddr("NewOps");
        vm.prank(admin);
        IAdmin(climeta).updateOpsTreasuryAddress(payable(newOps));
        assertEq(IAdmin(climeta).getOpsTreasuryAddress(), newOps);
        vm.prank(admin);
        IAdmin(climeta).updateOpsTreasuryAddress(payable(vm.envAddress("OPS_TREASURY_ADDRESS")));
        assertEq(IAdmin(climeta).getOpsTreasuryAddress(), payable(vm.envAddress("OPS_TREASURY_ADDRESS")));

    }

    function test_AdminFunctions() public {
        admin = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
        ops = IAdmin(climeta).getOpsTreasuryAddress();
        IVoting climetaCore = IVoting(climeta);
        Actors memory users;

        // Setup Ray and his reward pool wallet
        vm.startPrank(admin);
        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
        users.account0 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 0);
        rayward.mint(users.account0, REWARDPOOL_INITIAL);

        string memory abiFunc = "approve(address,uint256)";
        bytes memory callData = abi.encodeWithSignature(abiFunc, climeta, REWARDPOOL_INITIAL);
        RayWallet account0wallet = RayWallet(payable(users.account0));
        console.log("Owner of Ray Wallet ", account0wallet.owner());
        account0wallet.executeCall(raywardAddress, 0, callData);
        vm.stopPrank();

        users.user1 = makeAddr("user1");
        users.user2 = makeAddr("user2");
        users.user3 = makeAddr("user3");

        assertEq(rayward.balanceOf(users.user1), 0);
        assertEq(rayward.balanceOf(users.user2), 0);
        assertEq(rayward.balanceOf(users.user3), 0);

        vm.prank(users.user1);
        vm.expectRevert();
        climetaCore.sendRaywards(users.user1, 1_000);

        vm.prank(users.user1);
        vm.expectRevert();
        climetaCore.sendRaywards(users.user2, 1_000);

        vm.startPrank(admin);
        climetaCore.sendRaywards(users.user1, 1_000);
        climetaCore.sendRaywards(users.user2, 2_000);
        climetaCore.sendRaywards(users.user3, 3_000);
        vm.stopPrank();

        assertEq(rayward.balanceOf(users.user1), 1_000);
        assertEq(rayward.balanceOf(users.user2), 2_000);
        assertEq(rayward.balanceOf(users.user3), 3_000);
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
        (bool success,) = climeta.call{value: 1 ether}("");
        assert(!success);
    }

    function test_AddBeneficiary() public {
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        assertEq(IVoting(climeta).isBeneficiary(beneficiary1), false);
        assertEq(IVoting(climeta).isBeneficiary(beneficiary2), false);

        vm.prank(beneficiary1);
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
        vm.expectEmit();
        emit IVoting.Climeta__ProposalChanged(proposalId1, "proposal1-uri1a");
        IVoting(climeta).updateProposalMetadata(proposalId1, "proposal1-uri1a");
        (bene, uri) = IVoting(climeta).getProposal(proposalId1);
        assertEq(uri, "proposal1-uri1a");

        vm.prank(beneficiary2);
        vm.expectEmit();
        emit IVoting.Climeta__ProposalChanged(proposalId2, "proposal1-uri2a");
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

        vm.prank(beneficiary2);
        vm.expectRevert(IVoting.Climeta__NotProposalOwner.selector);
        IVoting(climeta).updateProposalMetadata(1111, "proposal1-uri2a");
    }

    function test_RaycognitionGranting() public {
        IVoting climetaCore = IVoting(climeta);
        Actors memory actor;
        actor.user1 = makeAddr("user1");
        actor.user2 = makeAddr("user2");
        actor.user3 = makeAddr("user3");

        // Mint NFTs to members directly and create the erc6551 raywallets
        vm.startPrank(admin);
        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
        delMundo.safeMint(actor.user1, 1, "uri-1");
        delMundo.safeMint(actor.user2, 2, "uri-2");
        delMundo.safeMint(actor.user3, 3, "uri-3");
        actor.account0 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 0);
        actor.account1 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 1);
        actor.account2 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 2);
        actor.account3 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 3);
        vm.stopPrank();

        // check that the wallets are correctly assigned to the right users
        assertEq(RayWallet(payable(actor.account1)).owner(), actor.user1);
        assertEq(RayWallet(payable(actor.account2)).owner(), actor.user2);
        assertEq(RayWallet(payable(actor.account3)).owner(), actor.user3);

        assertEq(raycognition.balanceOf(actor.account1), 0);
        assertEq(raycognition.balanceOf(actor.account2), 0);
        assertEq(raycognition.balanceOf(actor.account3), 0);
        assertEq(raycognition.balanceOf(actor.user1), 0);
        assertEq(raycognition.balanceOf(actor.user2), 0);
        assertEq(raycognition.balanceOf(actor.user3), 0);

        vm.prank(actor.user1);
        vm.expectRevert(LibDiamond.Climeta__NotAdmin.selector);
        climetaCore.grantRaycognition(1, 100);

        vm.prank(admin);
        climetaCore.grantRaycognition(1, 100);
        assertEq(raycognition.balanceOf(actor.user1),0);
        assertEq(raycognition.balanceOf(actor.account1),100);

        vm.prank(admin);
        climetaCore.grantRaycognition(2, 100);
        assertEq(raycognition.balanceOf(actor.user2),0);
        assertEq(raycognition.balanceOf(actor.account2),100);

        vm.prank(admin);
        climetaCore.grantRaycognition(1, 100);
        assertEq(raycognition.balanceOf(actor.user1),0);
        assertEq(raycognition.balanceOf(actor.account1),200);

    }

    function testFuzz_RaycognitionGrantingNonAdmin(address _notOwner) public {
        vm.assume(_notOwner != IOwnership(climeta).owner());
        IVoting climetaCore = IVoting(climeta);

        vm.prank(_notOwner);
        vm.expectRevert(LibDiamond.Climeta__NotAdmin.selector);
        climetaCore.grantRaycognition(1, 100);
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

    function testCastVote() public {
        IVoting climetaCore = IVoting(climeta);
        Actors memory actor;
        Proposals memory props;
        actor.beneficiary1 = makeAddr("beneficiary1");
        actor.beneficiary2 = makeAddr("beneficiary2");
        actor.user1 = makeAddr("user1");
        actor.user2 = makeAddr("user2");
        actor.user3 = makeAddr("user3");


        // Set up vote!
        vm.startPrank(admin);
        climetaCore.approveBeneficiary(actor.beneficiary1, true);
        climetaCore.approveBeneficiary(actor.beneficiary2, true);
        props.prop1 = climetaCore.addProposalByOwner(actor.beneficiary1, "proposal1-uri1");
        props.prop2 = climetaCore.addProposalByOwner(actor.beneficiary2, "proposal1-uri2");
        climetaCore.addProposalToVotingRound(props.prop1);
        climetaCore.addProposalToVotingRound(props.prop2);
        vm.stopPrank();

        // Ensure non members can't vote
        vm.startPrank(actor.user1);
        vm.expectRevert(IVoting.Climeta__NotRayWallet.selector);
        climetaCore.castVote(props.prop1);
        vm.stopPrank();

        vm.startPrank(address(this));
        vm.expectRevert();
        climetaCore.castVote(props.prop1);
        vm.stopPrank();
        assertEq(climetaCore.getVotes(props.prop1).length, 0);
        assertEq(climetaCore.getVotes(props.prop2).length, 0);

        // Mint NFTs to members directly and create the erc6551 raywallets
        vm.startPrank(admin);
        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
        delMundo.safeMint(actor.user1, 1, "uri-1");
        delMundo.safeMint(actor.user2, 2, "uri-2");
        delMundo.safeMint(actor.user3, 3, "uri-3");
        actor.account0 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 0);
        actor.account1 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 1);
        actor.account2 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 2);
        actor.account3 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 3);

        // mint some raywards to ray for rewards and then approve.
        rayward.mint(actor.account0, REWARDPOOL_INITIAL);
        // Check no users have any raywards yet
        assertEq(rayward.balanceOf(actor.account0), REWARDPOOL_INITIAL);
        assertEq(rayward.balanceOf(actor.account1), 0);
        assertEq(rayward.balanceOf(actor.account2), 0);
        assertEq(rayward.balanceOf(actor.account3), 0);

        string memory abiFunc = "approve(address,uint256)";
        bytes memory callData = abi.encodeWithSignature(abiFunc, climeta, REWARDPOOL_INITIAL);
        RayWallet account0wallet = RayWallet(payable(actor.account0));
        console.log("Owner of Ray Wallet ", account0wallet.owner());
        account0wallet.executeCall(raywardAddress, 0, callData);
        vm.stopPrank();

        // check that the wallets are correctly assigned to the right users
        assertEq(RayWallet(payable(actor.account1)).owner(), actor.user1);
        assertEq(RayWallet(payable(actor.account2)).owner(), actor.user2);
        assertEq(RayWallet(payable(actor.account3)).owner(), actor.user3);

        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
        abiFunc = "castVote(uint256)";

        // Test voting for non existent proposal
        props.callVote1 = abi.encodeWithSignature(abiFunc, 0);
        vm.startPrank(actor.user1);
        vm.expectRevert();
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        vm.stopPrank();

        console.log("Raycognitions minted before voting:", raycognition.totalSupply());

        props.callVote1 = abi.encodeWithSignature(abiFunc, props.prop1);
        props.callVote2 = abi.encodeWithSignature(abiFunc, props.prop2);

        vm.startPrank(actor.user1);
//        vm.expectEmit();
//        emit IVoting.Climeta__RaycognitionGranted(1, IAdmin(climeta).getVoteRaycognition());
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        vm.stopPrank();

        console.log("Raycognitions minted after voting:", raycognition.totalSupply());

        console.log("Raycog balance climeta: ",raycognition.balanceOf(climeta));
        console.log("Raycog balance account1: ",raycognition.balanceOf(actor.account1));
        console.log("Raycog balance account2: ",raycognition.balanceOf(actor.account2));
        console.log("Raycog balance account3: ",raycognition.balanceOf(actor.account3));
        console.log("Raycog balance user1: ",raycognition.balanceOf(actor.user1));
        console.log("Raycog balance user2: ",raycognition.balanceOf(actor.user2));
        console.log("Raycog balance user3: ",raycognition.balanceOf(actor.user3));


        // Ensure the right NFT is marked as having voted.
        assertFalse(climetaCore.hasVoted(0));
        assertTrue(climetaCore.hasVoted(1));
        assertFalse(climetaCore.hasVoted(2));
        assertFalse(climetaCore.hasVoted(3));
        assertFalse(climetaCore.hasVoted(300));

        assertEq(climetaCore.getVotes(props.prop1).length, 1);
        assertEq(climetaCore.getVotes(props.prop2).length, 0);

        vm.startPrank(actor.user1);
        vm.expectRevert(IVoting.Climeta__AlreadyVoted.selector);
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote2);
        vm.expectRevert(IVoting.Climeta__AlreadyVoted.selector);
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        vm.stopPrank();

        // Now user2 votes via his NFT
        vm.startPrank(actor.user2);
        vm.expectEmit();
        emit IVoting.Climeta__Vote(2, props.prop2);
        RayWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote2);
        vm.stopPrank();

        assertEq(climetaCore.getVotes(props.prop1).length, 1);
        assertEq(climetaCore.getVotes(props.prop2).length, 1);

        vm.startPrank(actor.user3);
        vm.expectEmit();
        emit IVoting.Climeta__Vote(3, props.prop2);
        RayWallet(payable(actor.account3)).executeCall(address(climetaCore), 0, props.callVote2);
        vm.stopPrank();
        assertEq(climetaCore.getVotes(props.prop1).length, 1);
        assertEq(climetaCore.getVotes(props.prop2).length, 2);

        assertEq(rayward.balanceOf(actor.account0), REWARDPOOL_INITIAL - (VOTING_REWARD*3));
        assertEq(rayward.balanceOf(actor.user1), VOTING_REWARD);
        assertEq(rayward.balanceOf(actor.user2), VOTING_REWARD);
        assertEq(rayward.balanceOf(actor.user3), VOTING_REWARD);

        // Test Raycognition goes to DelMundo wallet not owner.
        assertEq(raycognition.balanceOf(actor.user1), 0);
        assertEq(raycognition.balanceOf(actor.user2), 0);
        assertEq(raycognition.balanceOf(actor.user3), 0);
        assertEq(raycognition.balanceOf(actor.account1), IAdmin(climeta).getVoteRaycognition());
        assertEq(raycognition.balanceOf(actor.account2), IAdmin(climeta).getVoteRaycognition());
        assertEq(raycognition.balanceOf(actor.account3), IAdmin(climeta).getVoteRaycognition());
    }

    function test_EndVotingRound() public {
        ////////////// Voting test /////////////////
//        Vote 1 : Bene1/Prop1 1 Vote
//        Vote 1 : Bene2/Prop2 2 Vote
//        Vote 1 : ETH: 13.5
//        Voters: user1, user2, user3

//        Vote 2 : Bene1/Prop3 0 Vote
//        Vote 2 : Bene2/Prop4 2 Vote
//        Vote 2 : ETH: 0
//        Vote 2 : Stablecoin1 : 900
//        Vote 2 : Stablecoin2 : 90_000
//        Voters: user1, user2

//        Vote 3 : Bene1/Prop5 2 Vote
//        Vote 3 : Bene2/Prop6 0 Vote
//        Vote 3 : Bene3/Prop7 1 Vote
//        Vote 2 : ETH: 9
//        Vote 2 : Stablecoin1 : 9_000
//        Vote 2 : Stablecoin2 : 90_000
//        Voters: user1, user2, user3

        // Set up vote!
        IVoting climetaCore = IVoting(climeta);
        Actors memory actor;
        Proposals memory props;
        actor.beneficiary1 = makeAddr("beneficiary1");
        actor.beneficiary2 = makeAddr("beneficiary2");
        actor.beneficiary3 = makeAddr("beneficiary3");
        actor.brand1 = makeAddr("brand1");
        actor.brand2 = makeAddr("brand2");
        actor.user1 = makeAddr("user1");
        actor.user2 = makeAddr("user2");
        actor.user3 = makeAddr("user3");
        deal(actor.brand1, 100 ether);
        deal(actor.brand2, 100 ether);

        // Set up vote!
        vm.startPrank(admin);
        stablecoin1.mint(actor.brand1, 1_000_000);
        stablecoin1.mint(actor.brand2, 1_000_000);
        stablecoin2.mint(actor.brand1, 1_000_000);
        stablecoin2.mint(actor.brand2, 1_000_000);


        climetaCore.approveBeneficiary(actor.beneficiary1, true);
        climetaCore.approveBeneficiary(actor.beneficiary2, true);
        climetaCore.approveBeneficiary(actor.beneficiary3, true);
        props.prop1 = climetaCore.addProposalByOwner(actor.beneficiary1, "proposal1-uri1");
        props.prop2 = climetaCore.addProposalByOwner(actor.beneficiary2, "proposal1-uri2");
        props.prop3 = climetaCore.addProposalByOwner(actor.beneficiary1, "proposal1-uri3");
        props.prop4 = climetaCore.addProposalByOwner(actor.beneficiary2, "proposal1-uri4");
        props.prop5 = climetaCore.addProposalByOwner(actor.beneficiary1, "proposal1-uri5");
        props.prop6 = climetaCore.addProposalByOwner(actor.beneficiary2, "proposal1-uri6");
        props.prop7 = climetaCore.addProposalByOwner(actor.beneficiary3, "proposal1-uri7");
        climetaCore.addProposalToVotingRound(props.prop1);
        climetaCore.addProposalToVotingRound(props.prop2);
        vm.stopPrank();

        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
        string memory abiFunc = "castVote(uint256)";
        props.callVote1 = abi.encodeWithSignature(abiFunc, props.prop1);
        props.callVote2 = abi.encodeWithSignature(abiFunc, props.prop2);
        props.callVote3 = abi.encodeWithSignature(abiFunc, props.prop3);
        props.callVote4 = abi.encodeWithSignature(abiFunc, props.prop4);
        props.callVote5 = abi.encodeWithSignature(abiFunc, props.prop5);
        props.callVote6 = abi.encodeWithSignature(abiFunc, props.prop6);
        props.callVote7 = abi.encodeWithSignature(abiFunc, props.prop7);


        // Mint NFTs to members directly and create the erc6551 raywallets
        vm.startPrank(admin);
        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
        delMundo.safeMint(actor.user1, 1, "uri-1");
        delMundo.safeMint(actor.user2, 2, "uri-2");
        delMundo.safeMint(actor.user3, 3, "uri-3");
        actor.account0 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 0);
        actor.account1 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 1);
        actor.account2 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 2);
        actor.account3 = registry.createAccount(delMundoWalletAddress, 0, block.chainid, delMundoAddress, 3);

        // mint some raywards to ray for rewards and then approve.
        rayward.mint(actor.account0, REWARDPOOL_INITIAL);

        abiFunc = "approve(address,uint256)";
        bytes memory callData = abi.encodeWithSignature(abiFunc, climeta, REWARDPOOL_INITIAL);
        RayWallet account0wallet = RayWallet(payable(actor.account0));
        account0wallet.executeCall(raywardAddress, 0, callData);
        vm.stopPrank();

        // Get some donations
        vm.startPrank(actor.brand1);
        IDonation(climeta).donate{value: 5 ether}();
        vm.stopPrank();
        vm.startPrank(actor.brand2);
        IDonation(climeta).donate{value: 10 ether}();
        vm.stopPrank();
        assertEq(climeta.balance, 13.5 ether);

        vm.prank(actor.user1);
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        assertEq(Rayward(rayward).balanceOf(actor.user1), IAdmin(climeta).getVoteReward());

        vm.prank(actor.user2);
        RayWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote2);
        assertEq(Rayward(rayward).balanceOf(actor.user2), IAdmin(climeta).getVoteReward());

        vm.prank(actor.user3);
        RayWallet(payable(actor.account3)).executeCall(address(climetaCore), 0, props.callVote2);
        assertEq(Rayward(rayward).balanceOf(actor.user3), IAdmin(climeta).getVoteReward());

        // test the voting round has been incremented
        assertEq(climetaCore.getVotingRound(), 1);
        console.log("Voting for round one ended");
        vm.prank(admin);
        climetaCore.endVotingRound();
        vm.stopPrank();
        console.log("Ended round 1");

        // test the voting round has been incremented
        assertEq(climetaCore.getVotingRound(), 2);

        // balance should still be 13.5 ether as nothing has been pushed or withdrawn yet (after 10% to ops)
        assertEq(climeta.balance, 13.5 ether);
        // test that a withdrawal with nothing to withdraw does nothing
        uint256 prev_balance = actor.user1.balance;
        vm.prank(actor.user1);
        climetaCore.withdraw();
        assertEq(actor.user1.balance, prev_balance);

        // test that the beneficiary can withdraw all their funds.
        assertEq(actor.beneficiary1.balance, 0);
        vm.startPrank(actor.beneficiary1);
        uint256 gas_start = gasleft();
        climetaCore.withdraw();
        uint256 gas_used = gas_start - gasleft();
        vm.stopPrank();
        // 13.5 total. 2 proposals. beneficiary1 (prop1) got 1/3 of the votes so should get half of 10% of 13.5 + 33% of the 90%
        // 10% of 13.5 = 0.675
        // 90% of 13.5 = 12.15
        // 1/3 of 12.15 = 4.05
        // Total should be 4.725
        assertEq(actor.beneficiary1.balance, 4_725_000_000_000_000_000-(gas_used*tx.gasprice));
        vm.stopPrank();

        vm.startPrank(actor.beneficiary2);
        vm.expectRevert(LibDiamond.Climeta__NotAdmin.selector);
        climetaCore.pushPayment(actor.beneficiary2);
        vm.stopPrank();

        // test that we cna push the payments out to the charities if needed
        vm.prank(admin);
        climetaCore.pushPayment(actor.beneficiary2);

        // Test balance is 10% of total split between the two beneficiaries and then rest to #1
        // 13.5 total. 2 proposals. beneficiary2 (prop2) got 2/3 of the votes so should get half of 10% of 13.5 + 66% of the 90%
        // 10% of 13.5 = 0.675
        // 90% of 13.5 = 12.15
        // 2/3 of 12.15 = 8.1
        // Total should be 8.775
        assertEq(actor.beneficiary2.balance, 8_775_000_000_000_000_000);

        // Test the Raywards withdrawal works and that the other voters get the right amount after a rollover.
        // Amount is total allocated, minus all the individual vote rewards, divided by 2. First half split amongst all voters, second half split according to the relative raycognition scores of the voting delmundos.
        // Amount for each DelMundo without Raycog = (Total Available - (number of voters * votereward) ) / 2 / Total voted
        // Amount for each DelMundo with Raycog = (Total Available - (number of voters * votereward) ) / 2
        vm.prank(actor.user1);
        climetaCore.withdrawRaywards();

        ///////////////////////// VOTE 2 START /////////////////////////////////////
        // Need to test stablecoin donations as well as ETH ones
        // Set up vote #2
        vm.startPrank(admin);
        climetaCore.addProposalToVotingRound(props.prop3);
        climetaCore.addProposalToVotingRound(props.prop4);
        vm.stopPrank();

        vm.startPrank(actor.brand1);
        IDonation(climeta).donate{value: 5 ether}();
        stablecoin1.approve(climeta, 1_000);
        IDonation(climeta).donateToken(address(stablecoin1), 1_000);
        vm.stopPrank();

        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin1)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin1)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin1)) , 0);

        vm.startPrank(actor.brand2);
        stablecoin2.approve(climeta, 100_000);
        IDonation(climeta).donateToken(address(stablecoin2), 100_000);
        vm.stopPrank();

        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin2)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin2)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin2)) , 0);

        vm.prank(admin);
        vm.expectRevert(IVoting.Climeta__NoVotes.selector);
        climetaCore.endVotingRound();

        vm.prank(actor.user1);
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote4);
        vm.prank(actor.user2);
        RayWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote4);

        console.log("Voting complete");
        console.log("StableCoin2 before end vote2");
        console.log("StableCoin2");
        console.log("climeta : ", stablecoin2.balanceOf(address(climetaCore)));
        console.log("beneficiary2 eth : ", actor.beneficiary2.balance);
        console.log("beneficiary1 : ", stablecoin2.balanceOf(actor.beneficiary1));
        console.log("beneficiary2 : ", stablecoin2.balanceOf(actor.beneficiary2));
        console.log("beneficiary3 : ", stablecoin2.balanceOf(actor.beneficiary3));
        console.log("Amount of stablecoin2 for round :", climetaCore.getTokenAmountForRound(address(stablecoin2)));

        vm.startPrank(admin);
        // Set this round to be raywards withdraw only
        IAdmin(climeta).setWithdrawalOnly(true);
        climetaCore.endVotingRound();
        vm.stopPrank();

        // beneficiary 1 had no votes so gets a share of 10%, which = 45 stablecoin1 and 450 stblecoin2
        // beneficiary 2 had all the votes so gets a share of 10% and the full 90%, which = 855 stablecoin1 and 8,550 stblecoin2
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin1)) , 45);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin1)) , 855);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin1)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin2)) , 4_500);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin2)) , 85_500);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin2)) , 0);


        console.log("Total stablecoin2 donated :", IDonation(climeta).getTotalTokenDonations(address(stablecoin2)));
        console.log("beneficiary2 stable2 to withdraw : ", climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin2)));

        // test the voting round has been incremented
        assertEq(climetaCore.getVotingRound(), 3);

        // balance should still be 4.5 ether as nothing has been pushed or withdrawn yet
        assertEq(climeta.balance, 4.5 ether);
        assertEq(stablecoin1.balanceOf(climeta), 900);
        assertEq(stablecoin2.balanceOf(climeta), 90_000);

        // Rayward tests
        assertEq(rayward.balanceOf(actor.user1), 10_900);
        vm.prank(actor.user1);
        vm.expectEmit();
        emit IVoting.Climeta__RaywardClaimed(actor.user1, 55_000-10_900);
        climetaCore.withdrawRaywards();
        assertEq(rayward.balanceOf(actor.user1), 55_000);

        assertEq(rayward.balanceOf(actor.user3), 10_300);
        vm.prank(actor.user3);
        climetaCore.withdrawRaywards();
        assertEq(rayward.balanceOf(actor.user3), 10_300);

        assertEq(rayward.balanceOf(actor.user2), 10_900);
        vm.prank(actor.user2);
        vm.expectEmit();
        emit IVoting.Climeta__RaywardClaimed(actor.user2, 55_000-10_900);
        climetaCore.withdrawRaywards();
        assertEq(rayward.balanceOf(actor.user2), 55_000);

        // Charity withdrawals. Charity 2 doesn't - test a rollover.
        vm.startPrank(actor.beneficiary1);
        gas_start = gasleft();
        climetaCore.withdraw();
        gas_used = gas_start - gasleft();
        // Ensure that charity 1 get something - 5% in fact.
        assertEq(actor.beneficiary1.balance, 4_950_000_000_000_000_000-(gas_used*tx.gasprice));
        assertEq(stablecoin1.balanceOf(actor.beneficiary1), 45);
        assertEq(stablecoin2.balanceOf(actor.beneficiary1), 4500);
        vm.stopPrank();

        // Should be 0 as not withdrawn yet
        assertEq(stablecoin1.balanceOf(actor.beneficiary2), 0);
        assertEq(stablecoin2.balanceOf(actor.beneficiary2), 0);



        ///////////////////////// VOTE 3 START /////////////////////////////////////
        // Need to test stablecoin donations as well as ETH ones
        // Set up vote #2
        vm.startPrank(admin);
        climetaCore.addProposalToVotingRound(props.prop5);
        climetaCore.addProposalToVotingRound(props.prop6);
        climetaCore.addProposalToVotingRound(props.prop7);
        vm.stopPrank();

        vm.startPrank(actor.brand1);
        IDonation(climeta).donate{value: 10 ether}();
        stablecoin1.approve(climeta, 10_000);
        IDonation(climeta).donateToken(address(stablecoin1), 10_000);
        vm.stopPrank();

        vm.startPrank(actor.brand2);
        stablecoin2.approve(climeta, 100_000);
        IDonation(climeta).donateToken(address(stablecoin2), 100_000);
        vm.stopPrank();

        vm.prank(actor.user1);
        RayWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote5);
        vm.prank(actor.user2);
        RayWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote5);
        vm.prank(actor.user3);
        RayWallet(payable(actor.account3)).executeCall(address(climetaCore), 0, props.callVote7);

        vm.startPrank(admin);
        climetaCore.endVotingRound();
        vm.stopPrank();

        // Full withdrawals
//        Vote 1 : Bene1/Prop1 1 Vote
//        Vote 1 : Bene2/Prop2 2 Vote
//        Vote 1 : ETH: 13.5
//        Voters: user1, user2, user3

//        Vote 2 : Bene1/Prop3 0 Vote
//        Vote 2 : Bene2/Prop4 2 Vote
//        Vote 2 : ETH: 0
//        Vote 2 : Stablecoin1 : 900
//        Vote 2 : Stablecoin2 : 90_000
//        Voters: user1, user2

//        Vote 3 : Bene1/Prop5 2 Vote
//        Vote 3 : Bene2/Prop6 0 Vote
//        Vote 3 : Bene3/Prop7 1 Vote
//        Vote 2 : ETH: 9
//        Vote 2 : Stablecoin1 : 9_000
//        Vote 2 : Stablecoin2 : 90_000
//        Voters: user1, user2, user3



        // For Raywards, each total should be
        vm.prank(actor.user1);
        climetaCore.withdrawRaywards();
        assertEq(rayward.balanceOf(actor.user1), 94_400);

        vm.prank(actor.user2);
        climetaCore.withdrawRaywards();
        assertEq(rayward.balanceOf(actor.user2), 94_400);

        vm.prank(actor.user3);
        climetaCore.withdrawRaywards();
        assertEq(rayward.balanceOf(actor.user3), 20_600);

        vm.prank(actor.beneficiary1);
        climetaCore.withdraw();
        assertEq(actor.beneficiary1.balance ,10_650_000_000_000_000_000);

        vm.prank(actor.beneficiary2);
        climetaCore.withdraw();
        assertEq(actor.beneficiary2.balance ,13_350_000_000_000_000_000);

        vm.prank(actor.beneficiary3);
        climetaCore.withdraw();
        assertEq(actor.beneficiary3.balance ,3_000_000_000_000_000_000);

    }
}

