// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ClimetaCore.sol";

/// @title Climeta donation gateway to control incoming flow
/// @author matt@climeta.io
/// @notice This will be an upgradeable contract
/// @dev bugbounty contact mysaviour@climeta.io

contract Authorization is Initializable, AccessControl {

    event donation(address indexed _benefactor, uint256 timestamp, uint256 amount);
    event rejectedDonation(address indexed _benefactor, uint256 timestamp, uint256 amount);
    event approvedDonation(address indexed _benefactor, uint256 timestamp, uint256 amount);
    address payable private _opsTreasury;
    address payable private _votingContract;
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    // A donation is an amount and source pair to be approved donation by donation.
    struct Donation {
        address benefactor;
        uint256 amount;
    }

    Donation[] public donations;

    // gap param for storage blocking
    uint256[49] __gap;

    modifier onlyAdmin () {
        require (hasRole(CUSTODIAN_ROLE, msg.sender)  , "Not an admin");
        _;
    }

    function initialize(address _admin, address payable _ops, address payable _voting) public initializer {
        _grantRole(CUSTODIAN_ROLE, _admin);
        _opsTreasury = _ops;
        _votingContract = _voting;
    }

    function version() public pure returns (string memory) {
        return "1.0";
    }

    function removeFromArray(address _benefactor) private {
        for (uint256 i=0; i<donations.length;i++) {
            if (donations[i].benefactor == _benefactor) {
                for (uint256 j=i; j<donations.length-1; j++) {
                    donations[j] = donations[j+1];
                }
                donations.pop();
                return;
            }
        }
    }

    // Return an array of donators and an array of the amounts each that need to be processed.
    function getAllPendingDonations() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory _amounts = new uint256[](donations.length);
        address[] memory _benefactors = new address[](donations.length);
        for (uint256 i=0; i<donations.length;i++) {
            _amounts[i]= donations[i].amount;
            _benefactors[i] = donations[i].benefactor;
        }
        return (_benefactors, _amounts);
    }

    // Only allow the update of the Climeta treasury address. The voting contract is sacrosanct.
    function updateOpsAddress(address payable _ops) public onlyAdmin {
        _opsTreasury = _ops;
    }

    function approveDonation(address _approvedAddress, uint256 _amount) public onlyAdmin {
        for (uint256 i=0; i<donations.length;i++) {
            if ((donations[i].benefactor == _approvedAddress) && (donations[i].amount == _amount)) {
                for (uint256 j=i; j<donations.length-1; j++) {
                    donations[j] = donations[j+1];
                }
                donations.pop();
                payable(_opsTreasury).call{value:_amount * 10/100}("");
                ClimetaCore(_votingContract).donate{value: _amount * 90/100}(_approvedAddress);
                emit approvedDonation(_approvedAddress, block.timestamp, _amount);
                return;
            }
        }
    }

    function rejectDonation(address _rejectedAddress, uint256 _amount) public onlyAdmin {
        for (uint256 i=0; i<donations.length;i++) {
            if ((donations[i].benefactor == _rejectedAddress) && (donations[i].amount == _amount)) {
                for (uint256 j=i; j<donations.length-1; j++) {
                    donations[j] = donations[j+1];
                }
                donations.pop();
                payable(_rejectedAddress).call{value:_amount}("");
                emit rejectedDonation(_rejectedAddress, block.timestamp, _amount);
                return;
            }
        }
    }

    // Got sent some ETH
    receive() external payable {
        donations.push(Donation(msg.sender, msg.value));
        emit donation(msg.sender, block.timestamp, msg.value);
    }
}