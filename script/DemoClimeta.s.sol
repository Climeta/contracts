// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {Script, console} from "forge-std/Script.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import {IVoting} from "../src/interfaces/IVoting.sol";
import {IDonation} from "../src/interfaces/IDonation.sol";
import {IDiamondLoupe} from "../src//interfaces/IDiamondLoupe.sol";


contract DemoClimeta is Script {

    function run() external {
        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        uint256 brand1 = vm.envUint("ANVIL_BRAND1_PRIVATE_KEY");
        address brand1Addr = vm.envAddress("ANVIL_BRAND1_PUBLIC_KEY");
        uint256 charity1 = vm.envUint("ANVIL_CHARITY1_PRIVATE_KEY");
        address charity1Addr = vm.envAddress("ANVIL_CHARITY1_PUBLIC_KEY");
        uint256 charity2 = vm.envUint("ANVIL_CHARITY2_PRIVATE_KEY");
        address charity2Addr = vm.envAddress("ANVIL_CHARITY2_PUBLIC_KEY");
        uint256 owner = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address ownerAddr = vm.envAddress("DEPLOYER_PUBLIC_KEY");

        IDonation climetaDonation = IDonation(climetaAddress);

        vm.startBroadcast(brand1);
        climetaDonation.donate{value: 1_000}();
        vm.stopBroadcast();
        console.log("Balance of Climeta", climetaAddress.balance);

        IVoting climetaVoting = IVoting(climetaAddress);

        vm.startBroadcast(owner);
        uint256 propId = climetaVoting.addProposal(charity1Addr, "proposal1_uri");
        climetaVoting.addProposalToVotingRound(propId);
        propId = climetaVoting.addProposal(charity2Addr, "proposal2_uri");
        climetaVoting.addProposalToVotingRound(propId);
        console.log("Proposal id added ", propId);
        vm.stopBroadcast();

    }
}