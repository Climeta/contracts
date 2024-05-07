// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./token/Rayward.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TestReward is Ownable {

    address rayWallet;
    Rayward rayward;

    constructor(address _rayWallet, address _raywardAddress) Ownable(msg.sender){
        rayWallet = _rayWallet;
        rayward = Rayward(_raywardAddress);
    }

    function sendReward(address rewardee, uint256 amount) public onlyOwner {
        rayward.transferFrom(rayWallet, rewardee, amount);
    }
}
