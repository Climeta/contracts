// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {DonationStorage} from "../storage/DonationStorage.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

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
    function isAllowedToken(IERC20 _token) public view returns(bool) {
        return s.whitelistedTokens[address(_token)];
    }


    function donate(address _benefactor) payable external {
        s_totalDonatedAmount += msg.value;
        s_donations[_benefactor] += msg.value;
        emit Climeta__Donation(_benefactor, msg.value);
    }

    // @dev Pull some tokens from donator. They must have been pre-approved.
    function donateToken(IERC20 token, uint256 amount) external {
        // check if token is allowed
        if (!isAllowedToken(token)) {
            revert Climeta__NotValueToken();
        }
        DonationStorage.DonationStruct storage ds = DonationStorage.donationStorage();
        s.erc20Donations[address(token)][msg.sender] += amount;
        s.tokenBalances[address(token)] += amount;



        s_erc20Donations[msg.sender][address(token)] += amount;
        s_erc20DonatedTotals[address(token)] += amount;
        emit Climeta__ERC20Donation(msg.sender, address(token), amount);
        token.transferFrom(msg.sender, address(this), amount);

        uint256 opsAmount = (amount * 10) / 100;
        token.transfer(s_opsTreasury, opsAmount);
    }

}
