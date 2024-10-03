// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IDonation {
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

    function donationFacetVersion() external pure returns (string memory);
    function getMinimumERC20Donation(address _address) external view returns(uint256);
    function setMinimumERC20Donation(address _address, uint256 _amount) external;
    function getMinimumEthDonation() external view returns(uint256);
    function setMinimumEthDonation(uint256 _amount) external;
    function isAllowedToken(address _token) external view returns(bool);
    function donate() payable external;
    function donateToken(address _token, uint256 _amount) external;
}