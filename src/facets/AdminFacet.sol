// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import {IAdmin} from "../interfaces/IAdmin.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract AdminFacet is IAdmin {
    ClimetaStorage internal s;

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function adminFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    /////////////// GETTERS ////////////////////////////

    /// @notice gets the Ops Treasury address.
    function getOpsTreasuryAddress() external returns(address)  {
        return s.opsTreasuryAddress;
    }
    /// @notice gets the DelMundo contract address.
    function getDelMundoAddress() external returns(address)  {
        return s.delMundoAddress;
    }
    /// @notice gets the DelMundoTraits contract address.
    function getDelMundoTraitAddress() external returns(address)  {
        return s.delMundoTraitAddress;
    }
    /// @notice gets the Rayward contract address.
    function getRaywardAddress() external returns(address)  {
        return s.raywardAddress;
    }
    /// @notice gets the Rayputation contract address.
    function getRayputationAddress() external returns(address)  {
        return s.rayputationAddress;
    }
     /// @notice gets the ERC6551 Registry address.
    function getRegistryAddress() external returns(address)  {
        return s.registryAddress;
    }

    /////////////// SETTERS ////////////////////////////

    /**
    * @dev Update the ops address. Should be rarely called, if ever, but need the capability to do so. Covered by the onlyAdmin modifier
    * to ensure only admins can do this, given this is a 10% diversion of funds.
    * @param _ops The address of the new ops treasury.
    */
    function updateOpsTreasuryAddress(address payable _ops) external {
        LibDiamond.enforceIsContractOwner();
        s.opsTreasuryAddress = _ops;
    }


    /// @notice Adds a new beneficiary
    /// @param _beneficiary The address of the new beneficiary
    /// @param _name The name of the new beneficiary
    /// @param _dataURI The URI of the data associated with the new beneficiary
//    function addBeneficiary(address _beneficiary, string calldata _name, string calldata _dataURI) public onlyAdmin {
//        require(bytes(_name).length > 0, "Name cannot be empty" );
//        s_beneficiaries[_beneficiary].name = _name;
//        s_beneficiaries[_beneficiary].approved = true;
//        s_beneficiaries[_beneficiary].dataURI = _dataURI;
//        emit ClimetaCore__NewBeneficiary(_beneficiary, _name);
//    }
//
//    /// @notice Removes a beneficiary
//    /// @param _beneficiary The address of the beneficiary to remove
//    function removeBeneficiary(address _beneficiary) external onlyAdmin {
//        if (s_beneficiaries[_beneficiary].approved == true) {
//            s_beneficiaries[_beneficiary].approved = false;
//            s_beneficiaries[_beneficiary].name = "";
//            emit ClimetaCore__RemovedBeneficiary(_beneficiary);
//        }
//    }
}
