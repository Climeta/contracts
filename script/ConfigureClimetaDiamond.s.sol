// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {ClimetaDiamond} from "../src/ClimetaDiamond.sol";
import {Raycognition} from "../src/token/Raycognition.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import "../src/utils/DiamondHelper.sol";

contract ConfigureClimetaDiamond is Script, DiamondHelper {
    uint256 public constant VOTING_REWARD = 600;
    uint256 public constant VOTING_ROUND_REWARD = 60_000;

    function run(uint256 ownerPk, address _owner, uint256 deployPK, address _climeta, address _raycognition, address _delMundoTrait, address _rayWallet) public  {
        // Setup calls
        IAdmin(_climeta).setDelMundoTraitAddress(_delMundoTrait);
        Raycognition(_raycognition).grantMinter(_climeta);
        IAdmin(_climeta).setVoteReward(VOTING_REWARD);
        IAdmin(_climeta).setVotingRoundReward(VOTING_ROUND_REWARD);
        IAdmin(_climeta).setRayWalletAddress(_rayWallet);

    }
}
