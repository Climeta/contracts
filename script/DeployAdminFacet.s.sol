// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {ClimetaDiamond} from "../src/ClimetaDiamond.sol";
import "../src/facets/AdminFacet.sol";
import "../src/utils/DiamondHelper.sol";
import {IAdmin} from "../src/interfaces/IAdmin.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DeployAdminFacet is Script, DiamondHelper {
    uint256 public constant VOTING_REWARD = 600;
    uint256 public constant VOTING_ROUND_REWARD = 60_000;

    uint256 deployerPrivateKey;
    address deployerAddress;

    constructor(){
        deployerPrivateKey = vm.envUint("ANVIL_DEPLOYER_PRIVATE_KEY");
        deployerAddress = vm.envAddress("ANVIL_DEPLOYER_PUBLIC_KEY");
    }

    function deploy() external {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployerAddress = vm.envAddress("DEPLOYER_PUBLIC_KEY");
        run();
    }

    function run() public {
        vm.startBroadcast(deployerPrivateKey);

        AdminFacet adminFacet = new AdminFacet();

        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut ({
            facetAddress: address(adminFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("AdminFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climeta = IDiamondCut(climetaAddress);

        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IAdmin).interfaceId, true);

        IAdmin(address(climeta)).setVoteReward(VOTING_REWARD);
        IAdmin(address(climeta)).setVotingRoundReward(VOTING_ROUND_REWARD);
        vm.stopBroadcast();
    }
}
