// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../src/facets/DonationFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";

contract DeployDonationFacet is Script, DiamondHelper {
    function run() external {

        //read env variables and choose EOA for transaction signing
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_PUBLIC_KEY");

        vm.startBroadcast(deployerPrivateKey);

        //deploy facets and init contract
        DonationFacet donationFacet = new DonationFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        // FacetCut array which contains the three standard facets to be added
        cut[0] = FacetCut ({
            facetAddress: address(donationFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DonationFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");
        IDiamondCut climeta = IDiamondCut(climetaAddress);

        climeta.diamondCut(cut, address(0), "0x");
        vm.stopBroadcast();
    }
}
