// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../src/facets/DonationFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IDonation.sol";

contract DeployDonationFacet is Script, DiamondHelper {
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

        DonationFacet donationFacet = new DonationFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut ({
            facetAddress: address(donationFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("DonationFacet")
        });

        address climetaAddress = vm.envAddress("CLIMETA_ADDRESS");

        IDiamondCut climeta = IDiamondCut(climetaAddress);
        climeta.diamondCut(cut, address(0), "0x");
        climeta.diamondSetInterface(type(IDonation).interfaceId, true);

        vm.stopBroadcast();
    }
}
