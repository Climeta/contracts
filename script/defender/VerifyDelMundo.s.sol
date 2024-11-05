// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

contract VerifyDelMundo is Script {
    function run() public {
        string memory apiKey = vm.envString("ETHERSCAN_API_KEY");
        string memory contractAddress = vm.envString("CONTRACT_ADDRESS");
        string memory contractSource = "src/token/DelMundo.sol:DelMundo";

        console.log("Verifying contract at address", contractAddress);

        // Verify the contract
        string[] memory cmds = new string[](4);
        cmds[0] = "forge";
        cmds[1] = "verify-contract";
        cmds[2] = contractAddress;
        cmds[3] = contractSource;
        cmds[4] = apiKey;

        vm.ffi(cmds);
    }
}