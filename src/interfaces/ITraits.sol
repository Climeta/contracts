// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface ITraits {
    function isWearing(uint256 delMundoId, uint256 traitId) external view returns(bool);
    function updateTraits(uint256 delMundoId, uint256[] calldata traitIds) external;
    function getTraitsForDelMundo(uint256 delMundoId) external returns (uint256[] memory);
}