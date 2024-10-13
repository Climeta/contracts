// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ClimetaVestingWallet} from "../src/utils/ClimetaVestingWallet.sol";


contract DeployVestingWallet is Script {

    function deploy(address raywards, address beneficiary, uint64 startTimestamp, uint64 durationSeconds) external returns(address) {
        ClimetaVestingWallet vestingWallet = new ClimetaVestingWallet(raywards, beneficiary, startTimestamp, durationSeconds);
        return (address(vestingWallet));

    }
}