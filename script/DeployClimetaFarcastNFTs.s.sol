// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Script, console } from "forge-std/Script.sol";
import {ClimetaFarcasterNFTs} from "../src/token/ClimetaFarcasterNFTs.sol";
import {ClimetaSocialTokens} from "../src/token/ClimetaSocialTokens.sol";

contract DeployClimetaTokens is Script {

    function run() public {
        address owner = vm.envAddress("TEST_OWNER");
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);
        ClimetaFarcasterNFTs nft = new ClimetaFarcasterNFTs(owner, "");
        ClimetaSocialTokens tokens = new ClimetaSocialTokens(owner, "");
        console.log("CLIMETA_FACRACSTER_NFT_ADDRESS=", address(nft));
        console.log("CLIMETA_NFTS_ADDRESS=", address(tokens));
        vm.stopBroadcast();

        vm.startPrank(owner);
        tokens.updateURI(1, "uri");
        vm.stopPrank();
    }
}
