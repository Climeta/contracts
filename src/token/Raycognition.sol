// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @custom:security-contact matt@climeta.io
contract Raycognition is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant MINTER_ADMIN_ROLE = keccak256("MINTER_ADMIN_ROLE");

    error Raycognition__NotMinter();

    constructor(address _admin) ERC20("Raycognition", "RAYCOG") {
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(MINTER_ADMIN_ROLE, _admin);
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN_ROLE);
    }

    function decimals() public override pure returns (uint8) {
        return 9;
    }

    function _update(address from, address to, uint256 value) internal override {
        if (!hasRole(MINTER_ROLE, msg.sender)) {
            revert Raycognition__NotMinter();
        }
        super._update(from, to, value);
    }

    function grantMinter(address _newMinter) public onlyRole(MINTER_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _newMinter);
        _grantRole(MINTER_ADMIN_ROLE, _newMinter);
    }
    function revokeMinter(address _minter) public onlyRole(MINTER_ADMIN_ROLE) {
        _revokeRole(MINTER_ROLE, _minter);
        _revokeRole(MINTER_ADMIN_ROLE, _minter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
