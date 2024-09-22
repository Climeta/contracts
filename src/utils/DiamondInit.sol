// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

//******************************************************************************\
//* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
//* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
//*
//* Implementation of a diamond.
/******************************************************************************/

import { LibDiamond } from "../lib/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import {ClimetaStorage} from "../storage/ClimetaStorage.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init funciton if you need to.

// Adding parameters to the `init` or other functions you add here can make a single deployed
// DiamondInit contract reusable accross upgrades, and can be used for multiple diamonds.

contract DiamondInit {
    ClimetaStorage internal s;

    // You can add parameters to this function in order to pass in
    // data to set your own state variables
    function init(address _climeta, address _delMundo, address _rayWallet, address _rayward, address _rayputation, address _opsTreasury, address _registry) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // Set up all the relevant addresses for Climeta.
        s.climetaAddress = _climeta;
        s.delMundoAddress = _delMundo;
        s.opsTreasuryAddress = _opsTreasury;
        s.rayputationAddress = _rayputation;
    
        s.rayWalletAddress = _rayWallet;
        s.raywardAddress = _rayward;
        s.registryAddress = _registry;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}