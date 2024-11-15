// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {DonationStorage} from "../storage/DonationStorage.sol";
import {VotingStorage} from "../storage/VotingStorage.sol";
import {IDonation} from "../interfaces/IDonation.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Constants} from "../lib/Constants.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";

contract DonationFacet is IDonation {
    ClimetaStorage internal s;

    constructor() {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        ds.minimumEthDonation = 1 ether;
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function donationFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    function getTotalDonations() external view returns (uint256) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        return ds.totalDonatedAmount;
    }

    function getTotalTokenDonations(address _token) external view returns (uint256) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        return ds.totalTokenDonations[_token];
    }

    function getTokenDonations(address _donator, address _token) external view returns (uint256) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        return ds.erc20donations[_donator][_token];
    }
    function getDonations(address _donator) external view returns (uint256) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        return ds.donations[_donator];
    }

    function getMinimumERC20Donation(address _address) external view returns(uint256) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        return ds.minimumERC20Donations[_address];
    }

    function setMinimumERC20Donation(address _address, uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        ds.minimumERC20Donations[_address] = _amount;
    }

    function getMinimumEthDonation() external view returns(uint256) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        return ds.minimumEthDonation;
    }

    function setMinimumEthDonation(uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        ds.minimumEthDonation = _amount;
    }

    /// @notice Checks the ERC20 against list of allowed tokens
    /// @param _token The token to check
    function isAllowed(address _token) internal view returns(bool) {
        uint256 length = s.allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function hasDonatedERC20 (address _address) internal view returns (bool) {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        uint256 length = ds.erc20donators.length;
        for (uint256 i = 0; i < length; i++) {
            if (ds.erc20donators[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function donate() payable external {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();

        if (msg.value < ds.minimumEthDonation) {
            revert Climeta__DonationNotAboveThreshold();
        }
        emit Climeta__Donation(msg.sender, msg.value);
        // Add to list of donators if not donated before
        if (ds.donations[msg.sender] == 0) {
            ds.donators.push(msg.sender);
        }
        ds.totalDonatedAmount += msg.value;
        ds.donations[msg.sender] += msg.value;
        vs.roundDonations[vs.votingRound] += msg.value * (100-Constants.CLIMETA_PERCENTAGE )/ 100;

        // TODO Grant Raywards for donations if caller is a DelMundo holder

        // Send Climetas operations cut
        uint256 opsCut = msg.value * Constants.CLIMETA_PERCENTAGE / 100;
        (bool success, ) = s.opsTreasuryAddress.call{value: opsCut}("");
        require(success, "Failed to send ETH to Ops");
    }

    // @dev Pull some tokens from donator. They must have been pre-approved.
    function donateToken(address _token, uint256 _amount) external {
        // check if token is allowed
        if (!isAllowed(_token)) {
            revert Climeta__NotValueToken();
        }
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        VotingStorage.VotingStruct storage vs = VotingStorage.votingStorage();
        if (_amount < ds.minimumERC20Donations[_token]) {
            revert Climeta__DonationNotAboveThreshold();
        }
        if (!hasDonatedERC20(msg.sender)) {
            ds.erc20donators.push(msg.sender);
        }
        emit Climeta__ERC20Donation(msg.sender, _token, _amount);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        s.tokenBalances[_token] += _amount;
        ds.erc20donations[msg.sender][_token] += _amount;
        ds.totalTokenDonations[_token] += _amount;
        vs.roundERC20Donations[vs.votingRound][_token] += _amount * (100-Constants.CLIMETA_PERCENTAGE)/100;

        // TODO Grant Raywards for donations if caller is a DelMundo holder

        uint256 opsAmount = (_amount * Constants.CLIMETA_PERCENTAGE) / 100;
        IERC20(_token).transfer(s.opsTreasuryAddress, opsAmount);
    }

}
