// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";

struct Facet {
    address facetAddress;
    bytes4[] functionSelectors;
}

interface IClimeta {
    function facets() external view returns (Facet[] memory facets_) ;
    function adminFacetVersion() external pure returns (string memory);
    function getVotingRoundReward() external returns(uint256);
    function setVotingRoundReward(uint256 _rewardAmount) external;
    function getDelMundoAddress() external returns(address);
}

contract QueryClimeta is Script {

    function run() external {
        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IClimeta climeta = IClimeta(climetaAddress);
        console.log("Climeta address", address(climeta));

        Facet[] memory facets = climeta.facets();
        console.log("number of facets ", facets.length);
        console.log("Facet 1:", facets[0].facetAddress);


        string memory version = climeta.adminFacetVersion();
        console.log("AdminFacet version:", version);

        uint256 reward = climeta.getVotingRoundReward();
        console.log("Reward for voting round :", reward);
        climeta.setVotingRoundReward(100000);
        reward = climeta.getVotingRoundReward();
        console.log("Reward for voting round :", reward);

        address delMundoAddr = climeta.getDelMundoAddress();
        console.log("DelMundo Address stored :", delMundoAddr);

    }
}