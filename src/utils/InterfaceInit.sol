// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { LibDiamond } from "../lib/LibDiamond.sol";
import {ClimetaStorage} from "../storage/ClimetaStorage.sol";

contract InterfaceInit {
    ClimetaStorage internal s;

    function init(bytes4 _interfaceId) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[_interfaceId] = true;
    }
}
