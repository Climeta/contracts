// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract AdminFacet {
    ClimetaStorage internal s;

    /// @notice Emitted when a token is approved for use as treasury token
    /// @param _token The address of the ERC20 token added
    event Climeta__TokenApproved(address _token);
    event Climeta__VotingRewardChanged(uint256 amount);

    /// @notice Emitted when a token is revoked for use as treasury token
    /// @param _token The address of the ERC20 token removed
    event Climeta__TokenRevoked(address _token);

    error Climeta__ValueStillInContract();

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function adminFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    modifier onlyAdmin() {
        if (msg.sender != msg.sender) {
            revert();
        }
        _;
    }

    /// @notice Sets the amount of raywards given for the voting round. Can only be called by Admins
    /// @param _rewardAmount The new reward amount
    function setVotingRoundReward(uint256 _rewardAmount) public onlyAdmin {
        emit Climeta__VotingRewardChanged(_rewardAmount);
        s.votingRoundReward = _rewardAmount;
    }

    /**
    * @dev Update the ops address. Should be rarely called, if ever, but need the capability to do so. Covered by the onlyAdmin modifier
    * to ensure only admins can do this, given this is a 10% diversion of funds.
    * @param _ops The address of the new ops treasury.
    */
    function updateOpsAddress(address payable _ops) public onlyAdmin {
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

    /// @notice Checks the ERC20 against list of allowed tokens
    /// @param _token The token to check
    function isAllowedToken(address _token) internal view returns(bool) {
        uint256 length = s.allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allowedTokens[i] == address(_token)) {
                return true;
            }
        }
        return false;
    }

    /// @notice Adds an ERC20 to the list of allowed tokens
    /// @param _token The allowed token to add
    function addAllowedToken(IERC20 _token) public onlyAdmin {
        if (!isAllowedToken(address(_token))) {
            s.allowedTokens.push() = address(_token);
            emit Climeta__TokenApproved(address(_token));
        }
    }

    /// @notice Removes an ERC20 from the list of allowed tokens
    /// Cannot remove if there is still value left in the treasury.
    /// @param _token The allowed token to add
    function removeAllowedToken(IERC20 _token) public onlyAdmin {
        if (_token.balanceOf(address(this)) > 0) {
            revert Climeta__ValueStillInContract();
        }

        uint256 numberOfTokens = s.allowedTokens.length;
        // remove from array of proposals for this voting round
        for (uint256 i=0; i < numberOfTokens;i++) {
            if (s.allowedTokens[i] == address(_token)) {
                for (uint256 j=i; j + 1 < numberOfTokens ; j++ ) {
                    s.allowedTokens[j] = s.allowedTokens[j+1];
                }
                s.allowedTokens.pop();
                emit Climeta__TokenRevoked(address(_token));
                return;
            }
        }
    }

    // TODO need a solution to only be able to withdraw raywards from marketplace sales, not voting sales.
    // This is a potential way to drain funds. Need to think of how to handle this,
    // Maybe transfer trait sales raywards directly out to the opsWallet
    function withdrawRaywardTokens(address to, uint256 amount) external onlyOwner {
        require(IERC20(s.raywardAddress).transfer(to, amount), "Withdraw failed");
    }


}
