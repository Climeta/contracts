// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "./ClimetaCore.sol";

/*
 * @title Climeta donation gateway to control incoming flow
 * @author matt@climeta.io
 * @notice This will be an upgradeable contract
 * @dev bugbounty contact mysaviour@climeta.io
 * @dev This contract accepts donations and then the admins can either accept or reject. This allows control over who
 * can actually partake in Climeta's project funding and prevent unwanted donations.
 * Anyone self-destructing to this contract will lose their funds.
 * The contract will take a 10% fee (OPS_PERCENTAGE) and the rest will be sent to the voting contract.
 */
contract Authorization is Initializable, AccessControl, ReentrancyGuardUpgradeable {

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

    /**
    * @dev Throws if called by any account other than the admin.
    * Used to ensure only admins can perform core functions.
    */
    modifier onlyAdmin () {
        if (!hasRole(CUSTODIAN_ROLE, msg.sender)) {
            revert Authorization__NotAdmin();
        }
        _;
    }

    /**
    * @dev Just felt like the ops address storagte variable should be private...
    */
    function getOpsAddress() public view returns (address) {
        return _opsTreasury;
    }

    /**
    * @dev Initializer for this upgradeable contract.
    * @param _admin The address of the admin to be set as the first admin.
    * @param _ops The address of the ops treasury.
    * @param _voting The address of the voting contract to push funds to once approved.
    * @dev Also, admin role can grant other admins as well.
    */
    function initialize(address _admin, address payable _ops, address payable _voting) public initializer {
        _setRoleAdmin(CUSTODIAN_ROLE, ADMIN_CUSTODIAN_ROLE);
        _grantRole(CUSTODIAN_ROLE, _admin);
        _grantRole(ADMIN_CUSTODIAN_ROLE, _admin);
        _opsTreasury = _ops;
        _votingContract = _voting;
    }

    /**
    * @param _newAdmin Give you one guess what this does.
    * @dev Admin function to add in more admins.
    */
    function grantAdmin(address _newAdmin) public onlyRole(CUSTODIAN_ROLE) {
        _grantRole(CUSTODIAN_ROLE, _newAdmin);
        _grantRole(ADMIN_CUSTODIAN_ROLE, _newAdmin);
    }
    /**
    * @param _admin address of the admin to remove as an admin
    * @dev Admin function to remove a specific admins
    */
    function revokeAdmin(address _admin) public onlyRole(CUSTODIAN_ROLE) {
        _revokeRole(CUSTODIAN_ROLE, _admin);
        _revokeRole(ADMIN_CUSTODIAN_ROLE, _admin);
    }
    /**
    * @dev Versioning function for when upgrading to allow simple query to determine which one is in use.
    */
    function version() public pure returns (string memory) {
        return "1.0";
    }

    /**
    * @dev This returns 2 arrays of all the outstnading donations to process. Rejecting or Approving removes from the core
    * array, so this is a snapshot of the current state. This index position in each array should match, so _benefactor[1] donated _amounts[1]
    * @return _benefactors An array of addresses of the address who donated
    * @return _amounts An array of amounts donated.
    */
    function getAllPendingDonations() public view returns (address[] memory, uint256[] memory) {
        uint256[] memory _amounts = new uint256[](donations.length);
        address[] memory _benefactors = new address[](donations.length);
        for (uint256 i=0; i<donations.length;i++) {
            _amounts[i]= donations[i].amount;
            _benefactors[i] = donations[i].benefactor;
        }
        return (_benefactors, _amounts);
    }

    /**
    * @dev Update the ops address. Should be rarely called, if ever, but need the capability to do so. Covered by the onlyAdmin modifier
    * to ensure only admins can do this, given this is a 10% diversion of funds.
    * @param _ops The address of the new ops treasury.
    */
    function updateOpsAddress(address payable _ops) public onlyAdmin {
        _opsTreasury = _ops;
    }

    /**
    * @dev Approve a specific donation. Covered by the onlyAdmin modifier to ensure only admins can do this, given this is a
    * 10% diversion of funds.
    * We approve/reject each specific donation, not the total donation of the upstream donators so we have full control over who and what
    * is going to be voted on.
    * Donations are stored in an array, so we have to look for this specific donation and remove it
    * @param _approvedAddress The address of the beneficiary to approve
    * @param _amount The specific amount determining the donation  of the beneficiary to approve
    */
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

    /**
    * @dev Most donations are expected to be approved. This is a helper function to approve all donations in one go.
    * Given we have a loop of external calls, and even though we control the target ClimetaCore contract, we still have a
    * reentrancy guard in place, just to be on the safe side. The extra gas is no big deal and this function will not be used all the time
    */
    function approveAllDonations() external onlyAdmin nonReentrant {
        for (uint256 i=0; i<donations.length;i++) {
            payable(_opsTreasury).call{value:donations[i].amount * OPS_PERCENTAGE/100}("");
            ClimetaCore(_votingContract).donate{value: donations[i].amount * FUND_PERCENTAGE/100}(donations[i].benefactor);
            emit Authorization_ApprovedDonation(donations[i].benefactor, block.timestamp, donations[i].amount);
        }
        delete donations;
    }

    /**
    * @dev Reject a specific donation. Covered by the onlyAdmin modifier to ensure only admins can do this, given this is a
    * 10% diversion of funds and a core piece of Climeta.
    * We approve/reject each specific donation, not the total donation of the upstream donators so we have full control over who and what
    * is going to be voted on.
    * Donations are stored in an array, so we have to look for this specific donation and remove it
    * @param _rejectedAddress The address of the beneficiary to reject
    * @param _amount The specific amount determining the donation  of the beneficiary to reject
    */
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

    /**
    * @dev When we receive a donation, we store in a struct and push into an array where Climeta can review and determine to accept it or not.
    * We emit a specific event as well for off chain notification and just because we are state changing and its an event
    * in Climeta we need to action. This should be the only contract with a receive/fallback.
    */
    receive() external payable {
        donations.push(Donation(msg.sender, msg.value));
        emit Authorization_Donation(msg.sender, block.timestamp, msg.value);
    }
}
