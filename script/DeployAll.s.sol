    /// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DeployDelMundo} from "./DeployDelMundo.s.sol";
import {DeployDelMundoTrait} from "./DeployDelMundoTrait.s.sol";
import {DeployRayward} from "./DeployRayward.s.sol";
import {DeployClimetaDiamond} from "./DeployClimetaDiamond.s.sol";
import {DeployRaycognition} from "./DeployRaycognition.s.sol";
import {DeployTokenBoundRegistry} from "./DeployTokenBoundRegistry.s.sol";
import {DeployDiamondFacets} from "./DeployDiamondFacets.s.sol";
import {IERC6551Registry} from "@tokenbound/erc6551/interfaces/IERC6551Registry.sol";
import {DeployDelMundoWallet} from "./DeployDelMundoWallet.s.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import {IOwnership} from "../src/interfaces/IOwnership.sol";
import {Raycognition} from "../src/token/Raycognition.sol";
import {DeployDonationFacet} from "./DeployDonationFacet.s.sol";
import {DeployVotingFacet} from "./DeployVotingFacet.s.sol";
import {DeployMarketplaceFacet} from "./DeployMarketplaceFacet.s.sol";
import {DeployTraitFacet} from "./DeployTraitFacet.s.sol";

contract DeployAll is Script {

    /*
    *  Order of install
    *
    *   DelMundo
    *   Rayward
    *   Raycognition
    *   DelMundoWallet
    *   TokenBoundRegistry
    *   DiamondCut
    *   DiamondLoupe
    *   Ownership
    *   ClimetaDiamond
    *   DelMundoTrait
    *   AdminFacet
    *   DonationFacet
    *   VotingFacet
    *   MarketplaceFacet
    *   TraitFacet
    *   ClimetaAssets
    */

    struct Addresses {
        address delMundo;
        address rayward;
        address raycognition;
        address delMundoWallet;
        address registry;
        address rayWallet;
        address climeta;
        address delMundoTrait;
        address climetaAssets;
        address ops;
    }

    struct Deployers {
        DeployDelMundo delMundo;
        DeployRayward rayward;
        DeployRaycognition raycognition;
        DeployDelMundoWallet deployWallet;
        DeployTokenBoundRegistry registry;
        DeployClimetaDiamond climetaDeployer;
        DeployDelMundoTrait delMundoTrait;
        DeployDonationFacet donationDeployer;
        DeployVotingFacet votingDeployer;
        DeployMarketplaceFacet marketplaceDeployer;
        DeployTraitFacet traitDeployer;
    }

    function run(address _admin) public returns (Addresses memory) {
        Addresses memory addresses;
        Deployers memory deployers;

        deployers.delMundo = new DeployDelMundo();
        addresses.delMundo = deployers.delMundo.run(_admin);
        console.log("DELMUNDO_ADDRESS=", addresses.delMundo);

        deployers.rayward = new DeployRayward();
        addresses.rayward = deployers.rayward.run(_admin);
        console.log("RAYWARD_ADDRESS=", addresses.rayward);

        deployers.raycognition = new DeployRaycognition();
        addresses.raycognition = deployers.raycognition.run(_admin);
        console.log("RAYCOGNITION_ADDRESS=", addresses.raycognition);

        deployers.deployWallet = new DeployDelMundoWallet();
        addresses.delMundoWallet = deployers.deployWallet.run();
        console.log("DELMUNDOWALLET_ADDRESS=", addresses.delMundoWallet);

        deployers.registry = new DeployTokenBoundRegistry();
        addresses.registry = deployers.registry.run();
        console.log("REGISTRY_ADDRESS=", addresses.registry);
        addresses.rayWallet = IERC6551Registry(addresses.registry).account(addresses.delMundoWallet, 0, block.chainid, addresses.delMundo, 0);
        console.log("RAYWALLET_ADDRESS=", addresses.rayWallet);

        deployers.climetaDeployer = new DeployClimetaDiamond();
        addresses.climeta = deployers.climetaDeployer.run(_admin,addresses.delMundo,addresses.rayward, addresses.raycognition, addresses.rayWallet,addresses.delMundoWallet,  addresses.registry, addresses.ops);
        console.log("CLIMETA_ADDRESS=", addresses.climeta);

        deployers.delMundoTrait = new DeployDelMundoTrait();
        addresses.delMundoTrait = deployers.delMundoTrait.run(_admin, addresses.climeta);
        console.log("DELMUNDOTRAIT_ADDRESS=", addresses.delMundoTrait);


        return addresses;
    }
}
