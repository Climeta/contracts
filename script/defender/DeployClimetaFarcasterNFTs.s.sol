// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {ClimetaFarcasterNFTs} from "../../src/token/ClimetaFarcasterNFTs.sol";

import {DefenderOptions, Defender} from "openzeppelin-foundry-upgrades/Defender.sol";
import { TxOverrides } from "openzeppelin-foundry-upgrades/Options.sol";


contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        address admin = vm.envAddress("ADMIN_ADDRESS");
        string memory _uri = "URI";

        TxOverrides memory txOptions = TxOverrides({
            gasLimit: type(uint256).max,
            gasPrice: type(uint256).max,
            maxFeePerGas: type(uint256).max,
            maxPriorityFeePerGas: type(uint256).max
        });

        DefenderOptions memory options = DefenderOptions({
            useDefenderDeploy: true,
            skipVerifySourceCode: true,
            relayerId: "",
            salt: "0x",
            upgradeApprovalProcessId: "437be4e0-279d-4582-b132-4deda170a836",
            licenseType: "",
            skipLicenseType: true,
            txOverrides: txOptions
        });

        address deployed = Defender.deployContract("ClimetaFarcasterNFTs.sol", abi.encode(admin, _uri), options);
        console.log("Deployed contract to address", deployed);
    }
}
