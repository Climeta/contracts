// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import {IDiamondLoupe} from "../src//interfaces/IDiamondLoupe.sol";


contract QueryClimeta is Script {

    function run() external {
        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondLoupe climeta = IDiamondLoupe(climetaAddress);
        console.log("Climeta address", address(climeta));

        IDiamondLoupe.Facet[] memory facets = climeta.facets();
        console.log("number of facets ", facets.length);
        console.log("Facet 1:", facets[0].facetAddress);

        IAdmin climetaAdmin = IAdmin(climetaAddress);

        string memory version = climetaAdmin.adminFacetVersion();
        console.log("AdminFacet version:", version);

        uint256 reward = climetaAdmin.getVotingRoundReward();
        console.log("Reward for voting round :", reward);
        vm.startPrank(vm.envAddress("DEPLOYER_PUBLIC_KEY"));
        climetaAdmin.setVotingRoundReward(100_000);
        vm.stopPrank();
        reward = climetaAdmin.getVotingRoundReward();
        console.log("Reward for voting round :", reward);

        address delMundoAddr = climetaAdmin.getDelMundoAddress();
        console.log("DelMundo Address stored :", delMundoAddr);
        address opsAddr = climetaAdmin.getOpsTreasuryAddress();
        console.log("Ops Address stored :", opsAddr);

    }
}