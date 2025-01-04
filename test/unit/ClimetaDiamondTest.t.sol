// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdInvariant} from "../../lib/forge-std/src/StdInvariant.sol";
import {DeployAll} from "../../script/DeployAll.s.sol";
import {DeployClimetaDiamond} from "../../script/DeployClimetaDiamond.s.sol";
import {AdminFacet} from "../../src/facets/AdminFacet.sol";
import {DonationFacet} from "../../src/facets/DonationFacet.sol";
import {VotingFacet} from "../../src/facets/VotingFacet.sol";
import {MarketplaceFacet} from "../../src/facets/MarketplaceFacet.sol";
import {IOwnership} from "../../src/interfaces/IOwnership.sol";
import {IMarketplace} from "../../src/interfaces/IMarketplace.sol";
import {IAdmin} from "../../src/interfaces/IAdmin.sol";
import {IDonation} from "../../src/interfaces/IDonation.sol";
import {IVoting} from "../../src/interfaces/IVoting.sol";
import { LibDiamond } from "../../src/lib/LibDiamond.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {Rayward} from "../../src/token/Rayward.sol";
import {Raycognition} from "../../src/token/Raycognition.sol";
import {ERC6551Registry} from "@tokenbound/erc6551/ERC6551Registry.sol";
import {DelMundoWallet} from "../../src/DelMundoWallet.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {VotesMockUpgradeable} from "../../lib/openzeppelin-contracts-upgradeable/contracts/mocks/VotesMockUpgradeable.sol";
import "../../src/facets/AdminFacet.sol";
import "../../src/utils/DiamondHelper.sol";
import "../../src/interfaces/IDiamondCut.sol";

contract ClimetaDiamondTest is Test, DiamondHelper {
    uint256 public constant VOTING_REWARD = 600;
    uint256 public constant VOTE_RAYCOGNITION = 100;
    uint256 public constant VOTING_ROUND_REWARD = 60_000;
    uint256 public constant VOTE_MULTIPLIER = 1;
    uint256 public constant REWARDPOOL_INITIAL = 10_000_000_000_000;   // 10,000 raywards

    address ops;
    address admin;
    ERC6551Registry registry;
    Rayward rayward;
    Raycognition raycognition;
    DelMundo delMundo;
    ERC20Mock stablecoin1;
    ERC20Mock stablecoin2;
    DeployAll.Addresses contracts;

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
        ops = makeAddr("Ops");
        admin = makeAddr("Admin");

        vm.startPrank(admin);
        DeployAll deployer = new DeployAll();
        contracts = deployer.run(admin);

        // Deploy Facets
        AdminFacet adminFacet = new AdminFacet();
        FacetCut[] memory cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(adminFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("AdminFacet")
        });
        IDiamondCut climeta = IDiamondCut(contracts.climeta);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IAdmin).interfaceId, true);

        DonationFacet donationFacet = new DonationFacet();
        cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(donationFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DonationFacet")
        });
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IDonation).interfaceId, true);

        VotingFacet votingFacet = new VotingFacet();
        cut = new FacetCut[](1);
        cut[0] = FacetCut ({
            facetAddress: address(votingFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("VotingFacet")
        });
        bytes memory data = abi.encodeWithSignature("init()");
        climeta.diamondCut(cut, address(votingFacet), data);
        climeta.diamondSetInterface(type(IVoting).interfaceId, true);

        MarketplaceFacet marketplaceFacet = new MarketplaceFacet();
        cut = new FacetCut[](1);
        // remove supportsInterface
        cut[0] = FacetCut ({
            facetAddress: address(marketplaceFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("MarketplaceFacet")
        });
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IMarketplace).interfaceId, true);

        rayward = Rayward(contracts.rayward);
        delMundo = DelMundo(contracts.delMundo);
        registry = ERC6551Registry(contracts.registry);
        raycognition = Raycognition(contracts.raycognition);

        stablecoin1 = new ERC20Mock();
        stablecoin2 = new ERC20Mock();

        IAdmin(contracts.climeta).addAllowedToken(address(stablecoin1));
        IAdmin(contracts.climeta).addAllowedToken(address(stablecoin2));
        IAdmin(contracts.climeta).setWithdrawalOnly(false);
        IAdmin(contracts.climeta).setVoteReward(VOTING_REWARD);
        IAdmin(contracts.climeta).setVotingRoundReward(VOTING_ROUND_REWARD);
        IAdmin(contracts.climeta).updateOpsTreasuryAddress(payable(ops));
        raycognition.grantMinter(contracts.climeta);
        vm.stopPrank();

        rayward = Rayward(contracts.rayward);
        delMundo = DelMundo(contracts.delMundo);
        registry = ERC6551Registry(contracts.registry);
        raycognition = Raycognition(contracts.raycognition);
    }

    function test_Version() public view {
        assertEq(IAdmin(contracts.climeta).adminFacetVersion(), "1.0");
        assertEq(IDonation(contracts.climeta).donationFacetVersion(), "1.0");
        assertEq(IVoting(contracts.climeta).votingFacetVersion(), "1.0");
    }

    function test_Statics() public {
        uint256 reward = IAdmin(contracts.climeta).getVoteReward();
        console.log("Reward ", reward);
        assertEq(reward, VOTING_REWARD);
        vm.prank(admin);
        IAdmin(contracts.climeta).setVoteReward(VOTING_REWARD * 2);
        assertEq(IAdmin(contracts.climeta).getVoteReward(), VOTING_REWARD * 2);

        vm.prank(admin);
        IAdmin(contracts.climeta).setVotingRoundReward(VOTING_ROUND_REWARD * 2);
        assertEq(IAdmin(contracts.climeta).getVotingRoundReward(), VOTING_ROUND_REWARD * 2);

        vm.prank(admin);
        IAdmin(contracts.climeta).setVoteRaycognition(VOTE_RAYCOGNITION);
        assertEq(IAdmin(contracts.climeta).getVoteRaycognition(), VOTE_RAYCOGNITION);
        vm.prank(admin);
        IAdmin(contracts.climeta).setVoteRaycognition(VOTE_RAYCOGNITION*2);
        assertEq(IAdmin(contracts.climeta).getVoteRaycognition(), VOTE_RAYCOGNITION*2);

        assertEq(IAdmin(contracts.climeta).getDelMundoAddress(), contracts.delMundo);
        address newOps = makeAddr("NewOps");
        vm.prank(admin);
        IAdmin(contracts.climeta).updateOpsTreasuryAddress(payable(newOps));
        assertEq(IAdmin(contracts.climeta).getOpsTreasuryAddress(), newOps);

    }

    function test_AdminFunctions() public {
        ops = IAdmin(contracts.climeta).getOpsTreasuryAddress();
        IVoting climetaCore = IVoting(contracts.climeta);
        Actors memory users;

        // Setup Ray and his reward pool wallet
        vm.startPrank(admin);
        delMundo.safeMint(admin, 0, "uri-ray"); // This is Ray himself
        users.account0 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 0);
        IAdmin(contracts.climeta).setRayWalletAddress(users.account0);
        rayward.mint(users.account0, REWARDPOOL_INITIAL);

        string memory abiFunc = "approve(address,uint256)";
        bytes memory callData = abi.encodeWithSignature(abiFunc, contracts.climeta, REWARDPOOL_INITIAL);
        DelMundoWallet account0wallet = DelMundoWallet(payable(users.account0));
        console.log("Owner of Ray Wallet ", account0wallet.owner());
        account0wallet.executeCall(contracts.rayward, 0, callData);
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
        IOwnership(contracts.climeta).transferOwnership(newAdmin1);

        vm.prank(admin);
        IOwnership(contracts.climeta).transferOwnership(newAdmin1);
        assertEq(IOwnership(contracts.climeta).owner(), newAdmin1);

        vm.expectRevert();
        IOwnership(contracts.climeta).transferOwnership(newAdmin2);

        vm.prank(newAdmin1);
        IOwnership(contracts.climeta).transferOwnership(newAdmin2);
        assertEq(IOwnership(contracts.climeta).owner(), newAdmin2);
    }

    function test_TransferReverts() public {
        deal(address(this), 2 ether);
        (bool success,) = contracts.climeta.call{value: 1 ether}("");
        assert(!success);
    }

    function test_AddBeneficiary() public {
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary1), false);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary2), false);

        vm.prank(beneficiary1);
        vm.expectRevert();
        IVoting(contracts.climeta).approveBeneficiary(beneficiary1, true);

        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary1, true);
        vm.prank(admin);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary1, true);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary1), true);

        // Add second beneficiary
        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary2, true);
        vm.prank(admin);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary2, true);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary2), true);

        // Remove second beneficiary
        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary2, false);
        vm.prank(admin);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary2, false);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary2), false);

        // Add second back in
        vm.expectEmit();
        emit IVoting.Climeta__BeneficiaryApproval(beneficiary2, true);
        vm.prank(admin);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary2, true);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary2), true);

        // Remove both and add third time
        vm.startPrank(admin);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary1, false);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary2, false);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary1), false);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary2), false);

        // Add both in again
        IVoting(contracts.climeta).approveBeneficiary(beneficiary1, true);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary2, true);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary1), true);
        assertEq(IVoting(contracts.climeta).isBeneficiary(beneficiary2), true);
    }


    function test_AddUpdateProposal() public {
        assertEq(IVoting(contracts.climeta).getProposals(IVoting(contracts.climeta).getVotingRound()).length, 0);

        address notBeneficiary = makeAddr("notBeneficiary");
        address beneficiary1 = makeAddr("beneficiary1");
        address beneficiary2 = makeAddr("beneficiary2");
        vm.startPrank(admin);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary1, true);
        IVoting(contracts.climeta).approveBeneficiary(beneficiary2, true);
        vm.stopPrank();

        // Test only admin can add
        vm.prank(notBeneficiary);
        vm.expectRevert();
        IVoting(contracts.climeta).addProposalByOwner(beneficiary1, "proposal-uri");
        vm.prank(beneficiary1);
        vm.expectRevert();
        IVoting(contracts.climeta).addProposalByOwner(beneficiary1, "proposal-uri");

        vm.prank(notBeneficiary);
        vm.expectRevert();
        IVoting(contracts.climeta).addProposal("proposal-uri");

        vm.prank(beneficiary1);
        vm.expectEmit();
        emit IVoting.Climeta__NewProposal(beneficiary1, 1);
        uint256 proposalId1 = IVoting(contracts.climeta).addProposal("proposal-uri1");
        vm.prank(admin);
        vm.expectEmit();
        emit IVoting.Climeta__NewProposal(beneficiary2, 2);
        uint256 proposalId2 = IVoting(contracts.climeta).addProposalByOwner(beneficiary2, "proposal-uri2");

        address bene;
        string memory uri;
        (bene, uri) = IVoting(contracts.climeta).getProposal(proposalId1);
        assertEq(bene, beneficiary1);
        assertEq(uri, "proposal-uri1");
        (bene, uri) = IVoting(contracts.climeta).getProposal(proposalId2);
        assertEq(bene, beneficiary2);
        assertEq(uri, "proposal-uri2");

        // Test updates
        vm.prank(notBeneficiary);
        vm.expectRevert(IVoting.Climeta__NotProposalOwner.selector);
        IVoting(contracts.climeta).updateProposalMetadata(1, "proposal-uri1a");

        vm.prank(beneficiary2);
        vm.expectRevert(IVoting.Climeta__NotProposalOwner.selector);
        IVoting(contracts.climeta).updateProposalMetadata(proposalId1, "proposal-uri1a");

        vm.prank(beneficiary1);
        vm.expectEmit();
        emit IVoting.Climeta__ProposalChanged(proposalId1, "proposal1-uri1a");
        IVoting(contracts.climeta).updateProposalMetadata(proposalId1, "proposal1-uri1a");
        (bene, uri) = IVoting(contracts.climeta).getProposal(proposalId1);
        assertEq(uri, "proposal1-uri1a");

        vm.prank(beneficiary2);
        vm.expectEmit();
        emit IVoting.Climeta__ProposalChanged(proposalId2, "proposal1-uri2a");
        IVoting(contracts.climeta).updateProposalMetadata(proposalId2, "proposal1-uri2a");
        (bene, uri) = IVoting(contracts.climeta).getProposal(proposalId2);
        assertEq(uri, "proposal1-uri2a");

        // Add to voting round and ensure cant update any more
        vm.prank(admin);
        IVoting(contracts.climeta).addProposalToVotingRound(proposalId2);

        assertEq( IVoting(contracts.climeta).getProposals( IVoting(contracts.climeta).getVotingRound() ).length, 1);

        vm.prank(beneficiary2);
        vm.expectRevert(IVoting.Climeta__AlreadyInRound.selector);
        IVoting(contracts.climeta).updateProposalMetadata(proposalId2, "proposal1-uri2a");

        vm.prank(beneficiary2);
        vm.expectRevert(IVoting.Climeta__NotProposalOwner.selector);
        IVoting(contracts.climeta).updateProposalMetadata(1111, "proposal1-uri2a");
    }

    function test_RaycognitionGranting() public {
        IVoting climetaCore = IVoting(contracts.climeta);
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
        actor.account0 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 0);
        actor.account1 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 1);
        actor.account2 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 2);
        actor.account3 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 3);
        vm.stopPrank();

        // check that the wallets are correctly assigned to the right users
        assertEq(DelMundoWallet(payable(actor.account1)).owner(), actor.user1);
        assertEq(DelMundoWallet(payable(actor.account2)).owner(), actor.user2);
        assertEq(DelMundoWallet(payable(actor.account3)).owner(), actor.user3);

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
        vm.assume(_notOwner != IOwnership(contracts.climeta).owner());
        IVoting climetaCore = IVoting(contracts.climeta);

        vm.prank(_notOwner);
        vm.expectRevert(LibDiamond.Climeta__NotAdmin.selector);
        climetaCore.grantRaycognition(1, 100);
    }

    function test_VotingRounds() public {
        IVoting climetaCore = IVoting(contracts.climeta);
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

    function test_CastVote() public {
        IVoting climetaCore = IVoting(contracts.climeta);
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
        actor.account0 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 0);
        IAdmin(contracts.climeta).setRayWalletAddress(actor.account0);
        actor.account1 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 1);
        actor.account2 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 2);
        actor.account3 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 3);

        // mint some raywards to ray for rewards and then approve.
        rayward.mint(actor.account0, REWARDPOOL_INITIAL);

        // Check no users have any raywards yet
        assertEq(rayward.balanceOf(actor.account0), REWARDPOOL_INITIAL);
        assertEq(rayward.balanceOf(actor.account1), 0);
        assertEq(rayward.balanceOf(actor.account2), 0);
        assertEq(rayward.balanceOf(actor.account3), 0);

        string memory abiFunc = "approve(address,uint256)";
        bytes memory callData = abi.encodeWithSignature(abiFunc, address(climetaCore), REWARDPOOL_INITIAL);
        DelMundoWallet account0wallet = DelMundoWallet(payable(actor.account0));
        account0wallet.executeCall(contracts.rayward, 0, callData);
        vm.stopPrank();

        // check that the wallets are correctly assigned to the right users
        assertEq(DelMundoWallet(payable(actor.account1)).owner(), actor.user1);
        assertEq(DelMundoWallet(payable(actor.account2)).owner(), actor.user2);
        assertEq(DelMundoWallet(payable(actor.account3)).owner(), actor.user3);

        // User creates the calldata to cast the vote for the proposal they want and then calls the NFT wallet they own and want to use to actually do the vote.
        abiFunc = "castVote(uint256)";

        // Test voting for non existent proposal
        props.callVote1 = abi.encodeWithSignature(abiFunc, 0);
        vm.startPrank(actor.user1);
        vm.expectRevert();
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        vm.stopPrank();

        console.log("Raycognitions minted before voting:", raycognition.totalSupply());

        props.callVote1 = abi.encodeWithSignature(abiFunc, props.prop1);
        props.callVote2 = abi.encodeWithSignature(abiFunc, props.prop2);

        vm.startPrank(actor.user1);
//        vm.expectEmit();
//        emit IVoting.Climeta__RaycognitionGranted(1, IAdmin(contracts.climeta).getVoteRaycognition());
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        vm.stopPrank();

        console.log("Raycognitions minted after voting:", raycognition.totalSupply());

        console.log("Raycog balance contracts.climeta: ",raycognition.balanceOf(contracts.climeta));
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
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote2);
        vm.expectRevert(IVoting.Climeta__AlreadyVoted.selector);
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        vm.stopPrank();

        // Now user2 votes via his NFT
        vm.startPrank(actor.user2);
        vm.expectEmit();
        emit IVoting.Climeta__Vote(2, props.prop2);
        DelMundoWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote2);
        vm.stopPrank();

        assertEq(climetaCore.getVotes(props.prop1).length, 1);
        assertEq(climetaCore.getVotes(props.prop2).length, 1);

        vm.startPrank(actor.user3);
        vm.expectEmit();
        emit IVoting.Climeta__Vote(3, props.prop2);
        DelMundoWallet(payable(actor.account3)).executeCall(address(climetaCore), 0, props.callVote2);
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
        assertEq(raycognition.balanceOf(actor.account1), IAdmin(contracts.climeta).getVoteRaycognition());
        assertEq(raycognition.balanceOf(actor.account2), IAdmin(contracts.climeta).getVoteRaycognition());
        assertEq(raycognition.balanceOf(actor.account3), IAdmin(contracts.climeta).getVoteRaycognition());
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
        IVoting climetaCore = IVoting(contracts.climeta);
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
        actor.account0 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 0);
        IAdmin(contracts.climeta).setRayWalletAddress(actor.account0);
        actor.account1 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 1);
        actor.account2 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 2);
        actor.account3 = registry.createAccount(contracts.delMundoWallet, 0, block.chainid, contracts.delMundo, 3);

        // mint some raywards to ray for rewards and then approve.
        rayward.mint(actor.account0, REWARDPOOL_INITIAL);

        abiFunc = "approve(address,uint256)";
        bytes memory callData = abi.encodeWithSignature(abiFunc, contracts.climeta, REWARDPOOL_INITIAL);
        DelMundoWallet account0wallet = DelMundoWallet(payable(actor.account0));
        account0wallet.executeCall(contracts.rayward, 0, callData);
        vm.stopPrank();

        // Get some donations
        vm.startPrank(actor.brand1);
        IDonation(contracts.climeta).donate{value: 5 ether}();
        vm.stopPrank();
        vm.startPrank(actor.brand2);
        IDonation(contracts.climeta).donate{value: 10 ether}();
        vm.stopPrank();
        assertEq(contracts.climeta.balance, 13.5 ether);

        vm.prank(actor.user1);
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote1);
        assertEq(Rayward(rayward).balanceOf(actor.user1), IAdmin(contracts.climeta).getVoteReward());

        vm.prank(actor.user2);
        DelMundoWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote2);
        assertEq(Rayward(rayward).balanceOf(actor.user2), IAdmin(contracts.climeta).getVoteReward());

        vm.prank(actor.user3);
        DelMundoWallet(payable(actor.account3)).executeCall(address(climetaCore), 0, props.callVote2);
        assertEq(Rayward(rayward).balanceOf(actor.user3), IAdmin(contracts.climeta).getVoteReward());

        console.log("USER1 Raywards: ", rayward.balanceOf(actor.user1));
        // test the voting round has been incremented
        assertEq(climetaCore.getVotingRound(), 1);
        console.log("Voting for round one ended");
        vm.prank(admin);
        climetaCore.endVotingRound();
        console.log("Ended round 1");

        // test the voting round has been incremented
        assertEq(climetaCore.getVotingRound(), 2);

        // balance should still be 13.5 ether as nothing has been pushed or withdrawn yet (after 10% to ops)
        assertEq(contracts.climeta.balance, 13.5 ether);
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
        IDonation(contracts.climeta).donate{value: 5 ether}();
        stablecoin1.approve(contracts.climeta, 1_000);
        IDonation(contracts.climeta).donateToken(address(stablecoin1), 1_000);
        vm.stopPrank();

        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin1)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin1)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin1)) , 0);

        vm.startPrank(actor.brand2);
        stablecoin2.approve(contracts.climeta, 100_000);
        IDonation(contracts.climeta).donateToken(address(stablecoin2), 100_000);
        vm.stopPrank();

        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin2)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin2)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin2)) , 0);

        vm.prank(admin);
        vm.expectRevert(IVoting.Climeta__NoVotes.selector);
        climetaCore.endVotingRound();

        vm.prank(actor.user1);
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote4);
        vm.prank(actor.user2);
        DelMundoWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote4);


        console.log("Voting complete");
        console.log("StableCoin2");
        console.log("climeta : ", stablecoin2.balanceOf(address(climetaCore)));
        console.log("beneficiary2 eth : ", actor.beneficiary2.balance);
        console.log("beneficiary1 : ", stablecoin2.balanceOf(actor.beneficiary1));
        console.log("beneficiary2 : ", stablecoin2.balanceOf(actor.beneficiary2));
        console.log("beneficiary3 : ", stablecoin2.balanceOf(actor.beneficiary3));
        console.log("Amount of stablecoin2 for round :", climetaCore.getTokenAmountForRound(address(stablecoin2)));


        assertEq(rayward.balanceOf(actor.user1), 20_600); // This should be 20k from the first round and the 600 from voting.
        vm.startPrank(admin);
        // Set this round to be raywards withdraw only
        IAdmin(contracts.climeta).setWithdrawalOnly(true);
        climetaCore.endVotingRound();
        vm.stopPrank();
        assertEq(rayward.balanceOf(actor.user1), 20_600); // This should be the same, as the user now needs to withdraw after endVote.

        // beneficiary 1 had no votes so gets a share of 10%, which = 45 stablecoin1 and 450 stablecoin2
        // beneficiary 2 had all the votes so gets a share of 10% and the full 90%, which = 855 stablecoin1 and 8,550 stablecoin2
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin1)) , 45);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin1)) , 855);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin1)) , 0);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary1, address(stablecoin2)) , 4_500);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary2, address(stablecoin2)) , 85_500);
        assertEq(climetaCore.getWithdrawAmount(actor.beneficiary3, address(stablecoin2)) , 0);

        // test the voting round has been incremented
        assertEq(climetaCore.getVotingRound(), 3);

        // balance should still be 4.5 ether as nothing has been pushed or withdrawn yet
        assertEq(contracts.climeta.balance, 4.5 ether);
        assertEq(stablecoin1.balanceOf(contracts.climeta), 900);
        assertEq(stablecoin2.balanceOf(contracts.climeta), 90_000);

        // Rayward tests
//        assertEq(rayward.balanceOf(actor.user1), 20_600);
        vm.prank(actor.user1);
//        vm.expectEmit();
//        emit IVoting.Climeta__RaywardClaimed(actor.user1, (60_000 - 1_200) / 2);
        climetaCore.withdrawRaywards();
//        assertEq(rayward.balanceOf(actor.user1), ((60_000 - 1_200) / 2) + 20600 );

//        assertEq(rayward.balanceOf(actor.user2), 10_900);
        vm.prank(actor.user2);
//        vm.expectEmit();
//        emit IVoting.Climeta__RaywardClaimed(actor.user2, 55_000-10_900);
        climetaCore.withdrawRaywards();
//        assertEq(rayward.balanceOf(actor.user2), 55_000);
//
//        assertEq(rayward.balanceOf(actor.user3), 20_000);
        vm.prank(actor.user3);
        climetaCore.withdrawRaywards();
//        assertEq(rayward.balanceOf(actor.user3), 10_300);

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
        IDonation(contracts.climeta).donate{value: 10 ether}();
        stablecoin1.approve(contracts.climeta, 10_000);
        IDonation(contracts.climeta).donateToken(address(stablecoin1), 10_000);
        vm.stopPrank();

        vm.startPrank(actor.brand2);
        stablecoin2.approve(contracts.climeta, 100_000);
        IDonation(contracts.climeta).donateToken(address(stablecoin2), 100_000);
        vm.stopPrank();

        vm.prank(actor.user1);
        DelMundoWallet(payable(actor.account1)).executeCall(address(climetaCore), 0, props.callVote5);
        vm.prank(actor.user2);
        DelMundoWallet(payable(actor.account2)).executeCall(address(climetaCore), 0, props.callVote5);
        vm.prank(actor.user3);
        DelMundoWallet(payable(actor.account3)).executeCall(address(climetaCore), 0, props.callVote7);

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
//        assertEq(rayward.balanceOf(actor.user1), 94_400);

        vm.prank(actor.user2);
        climetaCore.withdrawRaywards();
//        assertEq(rayward.balanceOf(actor.user2), 94_400);

        vm.prank(actor.user3);
        climetaCore.withdrawRaywards();
//        assertEq(rayward.balanceOf(actor.user3), 20_600);

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

