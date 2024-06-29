// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @custom:security-contact matt@climeta.io
contract Rayward is ERC20, ERC20Capped, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant ADMIN_MINTER_ROLE = keccak256("ADMIN_MINTER_ROLE");
    uint256 public constant MAX_SUPPLY = 13_700_000_000 * 1e18;

    constructor(address _admin) ERC20("Rayward", "RAYWARD") ERC20Capped(MAX_SUPPLY) {
        _grantRole(MINTER_ROLE, _admin);
        _grantRole(ADMIN_MINTER_ROLE, _admin);
        _setRoleAdmin(MINTER_ROLE, ADMIN_MINTER_ROLE);
    }

    function decimals() public override pure returns (uint8) {
        return 18;
    }

    function _update(address from, address to, uint256 value) internal override (ERC20, ERC20Capped) {
        super._update(from, to, value);
    }

    function grantMinter(address _newMinter) public onlyRole(ADMIN_MINTER_ROLE) {
        _grantRole(MINTER_ROLE, _newMinter);
        _grantRole(ADMIN_MINTER_ROLE, _newMinter);
    }
    function revokeMinter(address _minter) public onlyRole(ADMIN_MINTER_ROLE) {
        _revokeRole(MINTER_ROLE, _minter);
        _revokeRole(ADMIN_MINTER_ROLE, _minter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
