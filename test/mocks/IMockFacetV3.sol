// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

interface IMockFacet {
    function mockFacetVersion() external pure returns (string memory);
    function getMockValueMapping2(uint256 _pos) external returns (uint256);
    function setMockValueMapping2(uint256 _pos, uint256 _value) external;
    function getMockValueMapping3(uint256 _pos) external returns (uint256);
    function setMockValueMapping3(uint256 _pos, uint256 _value) external;
}
