// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";

contract AdminFacet {
    ClimetaStorage internal s;

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function adminFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    /// @notice Adds a new beneficiary
    /// @param _beneficiary The address of the new beneficiary
    /// @param _name The name of the new beneficiary
    /// @param _dataURI The URI of the data associated with the new beneficiary
    function addBeneficiary(address _beneficiary, string calldata _name, string calldata _dataURI) public onlyAdmin {
        require(bytes(_name).length > 0, "Name cannot be empty" );
        s_beneficiaries[_beneficiary].name = _name;
        s_beneficiaries[_beneficiary].approved = true;
        s_beneficiaries[_beneficiary].dataURI = _dataURI;
        emit ClimetaCore__NewBeneficiary(_beneficiary, _name);
    }

    /// @notice Removes a beneficiary
    /// @param _beneficiary The address of the beneficiary to remove
    function removeBeneficiary(address _beneficiary) external onlyAdmin {
        if (s_beneficiaries[_beneficiary].approved == true) {
            s_beneficiaries[_beneficiary].approved = false;
            s_beneficiaries[_beneficiary].name = "";
            emit ClimetaCore__RemovedBeneficiary(_beneficiary);
        }
    }

}
