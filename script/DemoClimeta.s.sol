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
        address charity1Addr = vm.envAddress("ANVIL_CHARITY1_PUBLIC_KEY");
        address charity2Addr = vm.envAddress("ANVIL_CHARITY2_PUBLIC_KEY");
        uint256 owner = vm.envUint("DEPLOYER_PRIVATE_KEY");

        IDonation climetaDonation = IDonation(climetaAddress);

        vm.startBroadcast(brand1);
        climetaDonation.donate{value: 1_000}();
        vm.stopBroadcast();
        console.log("Balance of Climeta", climetaAddress.balance);

        IVoting climetaVoting = IVoting(climetaAddress);

        vm.startBroadcast(owner);
        climetaVoting.approveBeneficiary(charity1Addr, true);
        climetaVoting.approveBeneficiary(charity2Addr, true);
        uint256 propId = climetaVoting.addProposalByOwner(charity1Addr, "proposal1_uri");
        climetaVoting.addProposalToVotingRound(propId);
        propId = climetaVoting.addProposalByOwner(charity2Addr, "proposal2_uri");
        climetaVoting.addProposalToVotingRound(propId);
        console.log("Proposal id added ", propId);
        vm.stopBroadcast();

    }
}