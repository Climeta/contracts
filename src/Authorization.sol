// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./ClimetaCore.sol";

/// @title Climeta donation gateway to control incoming flow
/// @author matt@climeta.io
/// @notice This will be an upgradeable contract
/// @dev bugbounty contact mysaviour@climeta.io

contract Authorization is Initializable, AccessControl, ReentrancyGuard {

    event Authorization_Donation(address indexed _benefactor, uint256 timestamp, uint256 amount);
    event Authorization_RejectedDonation(address indexed _benefactor, uint256 timestamp, uint256 amount);
    event Authorization_ApprovedDonation(address indexed _benefactor, uint256 timestamp, uint256 amount);

    error Authorization__NotAdmin();

    address payable private _opsTreasury;
    address payable private _votingContract;
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");
    bytes32 public constant ADMIN_CUSTODIAN_ROLE = keccak256("ADMIN_CUSTODIAN_ROLE");
    uint64 public constant OPS_PERCENTAGE = 10;
    uint64 public constant FUND_PERCENTAGE = 90;

    // A donation is an amount and source pair to be approved donation by donation.
    struct Donation {
        address benefactor;
        uint256 amount;
    }

    Donation[] public donations;

    // gap param for storage blocking
    uint256[49] __gap;

    modifier onlyAdmin () {
        if (!hasRole(CUSTODIAN_ROLE, msg.sender)) {
            revert Authorization__NotAdmin();
        }
        _;
    }

    function getOpsAddress() public view returns (address) {
        return _opsTreasury;
    }

    function initialize(address _admin, address payable _ops, address payable _voting) public initializer {
        _setRoleAdmin(CUSTODIAN_ROLE, ADMIN_CUSTODIAN_ROLE);
        _grantRole(CUSTODIAN_ROLE, _admin);
        _grantRole(ADMIN_CUSTODIAN_ROLE, _admin);
        _opsTreasury = _ops;
        _votingContract = _voting;
    }

    // TODO - maybe create enumerable so that we check and never revoke all admins...
    function grantAdmin(address _newAdmin) public onlyRole(CUSTODIAN_ROLE) {
        _grantRole(CUSTODIAN_ROLE, _newAdmin);
        _grantRole(ADMIN_CUSTODIAN_ROLE, _newAdmin);
    }
    function revokeAdmin(address _admin) public onlyRole(CUSTODIAN_ROLE) {
        _revokeRole(CUSTODIAN_ROLE, _admin);
        _revokeRole(ADMIN_CUSTODIAN_ROLE, _admin);
    }

    function version() public pure returns (string memory) {
        return "1.0";
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

    function approveDonation(address _approvedAddress, uint256 _amount) external onlyAdmin {
        for (uint256 i=0; i<donations.length;i++) {
            if ((donations[i].benefactor == _approvedAddress) && (donations[i].amount == _amount)) {
                for (uint256 j=i; j<donations.length-1; j++) {
                    donations[j] = donations[j+1];
                }
                donations.pop();
                payable(_opsTreasury).call{value:_amount * OPS_PERCENTAGE/100}("");
                ClimetaCore(_votingContract).donate{value: _amount * FUND_PERCENTAGE/100}(_approvedAddress);
                emit Authorization_ApprovedDonation(_approvedAddress, block.timestamp, _amount);
                return;
            }
        }
    }

    function approveAllDonations() external onlyAdmin nonReentrant {
        for (uint256 i=0; i<donations.length;i++) {
            payable(_opsTreasury).call{value:donations[i].amount * OPS_PERCENTAGE/100}("");
            ClimetaCore(_votingContract).donate{value: donations[i].amount * FUND_PERCENTAGE/100}(donations[i].benefactor);
            emit Authorization_ApprovedDonation(donations[i].benefactor, block.timestamp, donations[i].amount);
        }
        delete donations;
    }

    function rejectDonation(address _rejectedAddress, uint256 _amount) external onlyAdmin {
        for (uint256 i=0; i<donations.length;i++) {
            if ((donations[i].benefactor == _rejectedAddress) && (donations[i].amount == _amount)) {
                for (uint256 j=i; j<donations.length-1; j++) {
                    donations[j] = donations[j+1];
                }
                donations.pop();
                payable(_rejectedAddress).call{value:_amount}("");
                emit Authorization_RejectedDonation(_rejectedAddress, block.timestamp, _amount);
                return;
            }
        }
    }

    // Got sent some ETH
    receive() external payable {
        donations.push(Donation(msg.sender, msg.value));
        emit Authorization_Donation(msg.sender, block.timestamp, msg.value);
    }
}
