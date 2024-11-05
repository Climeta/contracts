// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DelMundo} from "../../src/token/DelMundo.sol";
import {Raycognition} from "../../src/token/Raycognition.sol";

contract DeployDelMundo is Script {
    function run() external returns (address) {
        address admin = vm.envAddress("SAFE_OPS_WALLET");
        uint256 deployPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployPublicKey = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        address safeDEWallet = vm.envAddress("SAFE_DE_WALLET");
        vm.startBroadcast(deployPrivateKey);
        DelMundo delMundo = new DelMundo(deployPublicKey);
        delMundo = DelMundo(address(delMundo));
        delMundo.addAdmin(admin);
        delMundo.setDefaultRoyalites(safeDEWallet, 1_000);
//        delMundo.revokeAdmin(deployPublicKey);

        // Mint Ray
        delMundo.safeMint(admin, 0, "ipfs://QmPBtNF8xRxbcf1rSTAC57z2vDV5xma15KaobMbqpj8hhm");

        return (address(delMundo));
    }
}