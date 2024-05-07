// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact matt@climeta.io
contract Rayputation is ERC20Permit, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor() ERC20("Rayputation", "RAYPUTATION") ERC20Permit("Rayputation"){
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function decimals() public override pure returns (uint8) {
        return 9;
    }

    function _update(address from, address to, uint256 value) internal override {
        require( hasRole(MINTER_ROLE, msg.sender), "These tokens cannot be transferred, only earned" );
        super._update(from, to, value);
    }

    function grantMinter(address _newMinter) public onlyRole(MINTER_ROLE) {
        _grantRole(MINTER_ROLE, _newMinter);
    }
    function revokeMinter(address _newMinter) public onlyRole(MINTER_ROLE) {
        _revokeRole(MINTER_ROLE, _newMinter);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }
}
