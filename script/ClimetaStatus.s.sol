// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import {IVoting} from "../src/interfaces/IVoting.sol";
import {IDonation} from "../src/interfaces/IDonation.sol";
import {IDiamondLoupe} from "../src//interfaces/IDiamondLoupe.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

contract ClimetaStatus is Script {

    function run() external {
        console.log("");
        console.log("########### DIAMOND STATS ##############");
        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondLoupe climeta = IDiamondLoupe(climetaAddress);
        console.log("Climeta address", address(climeta));

        IDiamondLoupe.Facet[] memory facets = climeta.facets();
        console.log("number of facets ", facets.length);
        for (uint256 i = 0; i < facets.length; i++) {
            console.log("Facet ", i, ":", facets[i].facetAddress);
        }
        IAdmin climetaAdmin = IAdmin(climetaAddress);

        console.log("AdminFacet version:", climetaAdmin.adminFacetVersion());
        console.log("VotingFacet version:", IVoting(climetaAddress).votingFacetVersion());
        console.log("DonationFacet version:", IDonation(climetaAddress).donationFacetVersion());

        console.log("");
        console.log("########### CORE ADDRESSES ##############");
        console.log("DELMUNDO_ADDRESS=", climetaAdmin.getDelMundoAddress());
        console.log("DELMUNDOTRAIT_ADDRESS=", climetaAdmin.getDelMundoTraitAddress());
        console.log("DELMUNDOWALLET_ADDRESS=", climetaAdmin.getDelMundoWalletAddress());
        console.log("RAYCOGNITION_ADDRESS=", climetaAdmin.getRaycognitionAddress());
        console.log("RAYWARD_ADDRESS=", climetaAdmin.getRaywardAddress());
        console.log("RAYWALLET_ADDRESS=", climetaAdmin.getRayWalletAddress());
        console.log("REGISTRY_ADDRESS=", climetaAdmin.getRegistryAddress());
        console.log("OPS_TREASURY_ADDRESS=", climetaAdmin.getOpsTreasuryAddress());

        console.log("");
        console.log("########### CURRENT VALUES ##############");
        console.log("Reward for voting round :", climetaAdmin.getVotingRoundReward());
        console.log("Reward for a vote :", climetaAdmin.getVoteReward());
        console.log("Raycognition for a vote :", climetaAdmin.getVoteRaycognition());
        address[] memory tokens = climetaAdmin.getAllowedTokens();
        for (uint256 i = 0; i < tokens.length; i++) {
            console.log("Allowed token : ", tokens[i]);
        }

        console.log("");
        console.log("########### FINANCIALS ##############");
        for (uint256 i = 0; i < tokens.length; i++) {
            console.log("Total in fund for : ", tokens[i], " is ", IERC20(tokens[i]).balanceOf(climetaAddress));
        }
        console.log("Reward Pool Size : ", IERC20(climetaAdmin.getRaywardAddress()).balanceOf(climetaAdmin.getRayWalletAddress()));
        console.log("Value to be withdrawn from DelMundos : ", climetaAdmin.getDelMundoAddress().balance);
        console.log("Total DelMundos redeemed : ", IERC721Enumerable(climetaAdmin.getDelMundoAddress()).totalSupply());

        console.log("");
        console.log("########### VOTING ROUND ##############");
        for (uint256 i=1; i <= IVoting(climetaAddress).getVotingRound(); i++) {
            console.log("Voting round :", i );
            for (uint256 j=0; j < IVoting(climetaAddress).getProposals(i).length; j++) {
                console.log("Proposal ", j, " vote count: ", IVoting(climetaAddress).getVotes(j).length);
            }
        }
    }
}