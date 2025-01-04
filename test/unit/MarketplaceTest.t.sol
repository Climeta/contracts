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
import {DeployMarketplaceFacet} from "../../script/DeployMarketplaceFacet.s.sol";
import "../../src/facets/AdminFacet.sol";
import "../../src/utils/DiamondHelper.sol";
import "../../src/interfaces/IDiamondCut.sol";

contract MarketplaceTest is Test, DiamondHelper {

    //    Authorization auth;
    address ops;
    address admin;
    DelMundo delMundo;
    Rayward rayward;
    Raycognition raycognition;
    ERC6551Registry registry;
    DelMundoWallet delMundoWallet;
    ERC20Mock stablecoin1;
    ERC20Mock stablecoin2;
    DeployAll.Addresses contracts;

    struct Actors {
        address user1;
        address user2;
        address user3;
        address user4;
        address user5;
        address user6;
        address user7;
        address user8;
        address brand1;
        address brand2;
    }

    function setUp() public {
        ops = makeAddr("Ops");
        admin = makeAddr("Admin");

        console.log("Admin address: ", admin);

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
        vm.stopPrank();
    }

    function test_Version() public view {
        assertEq(IMarketplace(contracts.climeta).marketplaceFacetVersion(), "1.0");
    }

}

