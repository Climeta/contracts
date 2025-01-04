// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {ClimetaStorage} from "../storage/ClimetaStorage.sol";
import {TraitStorage} from "../storage/TraitStorage.sol";
import {LibDiamond} from "../lib/LibDiamond.sol";
import {ITraits} from "../interfaces/ITraits.sol";

contract TraitFacet is ITraits {
    ClimetaStorage internal s;

    constructor() {
    }

    function traitFacetVersion() external pure returns(string memory) {
        return "1.0";
    }

    function isWearing(uint256 delMundoId, uint256 traitId) external view returns(bool) {
        TraitStorage.TraitStruct storage ts = TraitStorage.traitStorage();
        for (uint256 i = 0; i < ts.delMundoTraits[delMundoId].length; i++) {
            if (ts.delMundoTraits[delMundoId][i] == traitId) {
                return true;
            }
        }
        return false;
    }

    function updateTraits(uint256 delMundoId, uint256[] calldata traitIds) external {
        LibDiamond.enforceIsContractOwner();
        TraitStorage.TraitStruct storage ts = TraitStorage.traitStorage();
        ts.delMundoTraits[delMundoId] = traitIds;
    }

    function getTraitsForDelMundo(uint256 delMundoId) external returns (uint256[] memory) {
        TraitStorage.TraitStruct storage ts = TraitStorage.traitStorage();
        return ts.delMundoTraits[delMundoId];
    }
}