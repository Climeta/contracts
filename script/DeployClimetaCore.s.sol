// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ClimetaCore} from "../src/ClimetaCore.sol";

contract DeployClimetaCore is Script {

    function run(address admin, address delMundoAddress, address raywardAddress, address rayRegistryAddress, address rayWalletAddress) external returns (address) {
        ClimetaCore climetaCore = new ClimetaCore();
        climetaCore.initialize(admin, delMundoAddress, raywardAddress, rayRegistryAddress, rayWalletAddress);
        return (address(climetaCore));
    }
}