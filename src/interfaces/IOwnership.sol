// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IOwnership {
    function transferOwnership(address) external;
    function owner() external view returns (address);
}
