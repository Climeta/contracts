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
    /// @notice gets the DelMundoTraits contract address.
    function getDelMundoWalletAddress() external returns(address)  {
        return s.delMundoWalletAddress;
    }
    /// @notice gets the Rayward contract address.
    function getRaywardAddress() external returns(address)  {
        return s.raywardAddress;
    }
    /// @notice gets the Raycognition contract address.
    function getRaycognitionAddress() external returns(address)  {
        return s.raycognitionAddress;
    }
     /// @notice gets the ERC6551 Registry address.
    function getRegistryAddress() external returns(address)  {
        return s.registryAddress;
    }

    /// @notice gets the amount of raywards given for the voting round.
    function getVotingRoundReward() external returns(uint256)  {
        return s.votingRoundReward;
    }
    /// @notice Sets the amount of raywards given for the voting round. Can only be called by Admins
    /// @param _rewardAmount The new reward amount
    function setVotingRoundReward(uint256 _rewardAmount) external {
        LibDiamond.enforceIsContractOwner();
        emit Climeta__VotingRewardChanged(_rewardAmount);
        s.votingRoundReward = _rewardAmount;
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

    /// @notice Checks the ERC20 against list of allowed tokens
    /// @param _token The token to check
    function isAllowedToken(address _token) internal view returns(bool) {
        uint256 length = s.allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    /// @notice Adds an ERC20 to the list of allowed tokens
    /// @param _token The allowed token to add
    function addAllowedToken(address _token) external {
        LibDiamond.enforceIsContractOwner();
        if (!isAllowedToken(_token)) {
            s.allowedTokens.push() = _token;
            emit Climeta__TokenApproved(_token);
        }
    }

    /// @notice Removes an ERC20 from the list of allowed tokens
    /// Cannot remove if there is still value left in the treasury.
    /// @param _token The allowed token to add
    function removeAllowedToken(address _token) external {
        LibDiamond.enforceIsContractOwner();
        if (IERC20(_token).balanceOf(address(this)) > 0) {
            revert Climeta__ValueStillInContract();
        }

        uint256 numberOfTokens = s.allowedTokens.length;
        // remove from array of proposals for this voting round
        for (uint256 i=0; i < numberOfTokens;i++) {
            if (s.allowedTokens[i] == _token) {
                for (uint256 j=i; j + 1 < numberOfTokens ; j++ ) {
                    s.allowedTokens[j] = s.allowedTokens[j+1];
                }
                s.allowedTokens.pop();
                emit Climeta__TokenRevoked(address(_token));
                return;
            }
        }
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
