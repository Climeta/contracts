// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../../src/storage/ClimetaStorage.sol";
import {MockStorage} from "../mocks/MockStorage.sol";
import {LibDiamond} from "../../src/lib/LibDiamond.sol";

contract MockFacet {
    ClimetaStorage internal s;

    constructor(){
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function mockFacetVersion() external pure returns (string memory) {
        return "1.0";
    }

    function getMockValueMapping1(uint256 _pos) external returns (uint256) {
        MockStorage.MockStruct storage ms = MockStorage.mockStorage();
        return ms.mapping1[_pos];
    }
    function setMockValueMapping1(uint256 _pos, uint256 _value) external {
        LibDiamond.enforceIsContractOwner();
        MockStorage.MockStruct storage ms = MockStorage.mockStorage();
        ms.mapping1[_pos] = _value;
    }
}