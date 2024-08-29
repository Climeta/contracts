// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import {ClimetaFarcasterNFTs} from "../src/token/ClimetaFarcasterNFTs.sol";

contract DeployClimetaFarcasterNFTs is Script {

    function run(address owner, string calldata uri) public {
        vm.startBroadcast();
        ClimetaFarcasterNFTs nft = new ClimetaFarcasterNFTs(owner, uri);
        vm.stopBroadcast();
    }

}
