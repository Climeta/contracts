// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {VestingWallet} from "@openzeppelin/contracts/finance/VestingWallet.sol";

contract ClimetaVestingWallet is VestingWallet{
    address private raywards;

    constructor(address _raywards, address beneficiary, uint64 startTimestamp, uint64 durationSeconds) VestingWallet (beneficiary,startTimestamp,durationSeconds) {
        raywards = _raywards;
    }

    function getMyRaywards() external {
        this.release(raywards);
    }
}
