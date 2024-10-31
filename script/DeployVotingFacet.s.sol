// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../src/facets/VotingFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DeployVotingFacet is Script, DiamondHelper {
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

        //deploy facets and init contract
        VotingFacet votingFacet = new VotingFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        // FacetCut array which contains the three standard facets to be added
        cut[0] = FacetCut ({
            facetAddress: address(votingFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("VotingFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climeta = IDiamondCut(climetaAddress);

        bytes memory data = abi.encodeWithSignature("init()");

        climeta.diamondCut(cut, address(votingFacet), data);
        vm.stopBroadcast();
    }
}
