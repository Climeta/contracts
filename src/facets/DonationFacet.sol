// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {DonationStorage} from "../storage/DonationStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Constants} from "../lib/Constants.sol";

contract DonationFacet {
    ClimetaStorage internal s;

    /// @notice Emitted when a donation is made
    /// @param _benefactor The address of the benefactor making the donation
    /// @param _amount The amount of the donation
    event Climeta__Donation(address _benefactor, uint256 _amount);

    /// @notice Emitted when an ERC20 donation is made
    /// @param _benefactor The address of the benefactor making the donation
    /// @param _token The ERC20 token donated
    /// @param _amount The amount of the donation
    event Climeta__ERC20Donation(address _benefactor, address _token, uint256 _amount);

    error Climeta__NotValueToken();
    error Climeta__DonationNotAboveThreshold();

    constructor() {
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        ds.minimumDonation = 0;
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function donationFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    /**
    * @dev ETH Donations should only come from approved sources
    *
    * The 90/10 split is done on approval.
    *
    * We accept that if someone self-destructs a contract, the funds will get wrapped up and distributed to the projects
    * but it will not be registered as a formal donation, the funds will just get sent out anonymously and not tracked.
    *
    * Each donation is logged formally for tracking and transparency as a key component of fund flow. An event is emitted
    * so these can be tracked off chain too, self-destruct aside.
    *
    * @param _benefactor The ID of the donator.
    */
    /// @notice Checks the ERC20 against list of allowed tokens
    /// @param _token The token to check
    function isAllowedToken(address _token) public view returns(bool) {
        uint256 length = s.allowedTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (s.allowedTokens[i] == address(_token)) {
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
        if (msg.value < ds.minimumDonation) {
            revert Climeta__DonationNotAboveThreshold();
        }
        emit Climeta__Donation(msg.sender, msg.value);
        // Add to list of donators if not donated before
        if (ds.donations[msg.sender] == 0) {
            ds.donators.push(msg.sender);
        }
        ds.totalDonatedAmount += msg.value;
        ds.donations[msg.sender] += msg.value;

        // Send Climetas operations cut
        uint256 opsCut = msg.value * Constants.CLIMETA_PERCENTAGE / 100;
        s.opsTreasuryAddress.call{value: opsCut}("");
    }

    // @dev Pull some tokens from donator. They must have been pre-approved.
    function donateToken(IERC20 token, uint256 amount) external {
        // check if token is allowed
        if (!isAllowedToken(address(token))) {
            revert Climeta__NotValueToken();
        }
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        if (!hasDonatedERC20(msg.sender)) {
            ds.erc20donators.push(msg.sender);
        }
        emit Climeta__ERC20Donation(msg.sender, address(token), amount);
        token.transferFrom(msg.sender, address(this), amount);
        s.tokenBalances[address(token)] += amount;
        ds.erc20donations[msg.sender][address(token)] += amount;
        ds.totalTokenDonations[address(token)] += amount;

        uint256 opsAmount = (amount * Constants.CLIMETA_PERCENTAGE) / 100;
        token.transfer(s.opsTreasuryAddress, opsAmount);
    }

}
