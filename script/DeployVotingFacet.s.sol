// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import "../src/ClimetaDiamond.sol";
import "../src/facets/VotingFacet.sol";
import "../src/utils/DiamondHelper.sol";
import "../src/interfaces/IDiamondCut.sol";
import "../src/interfaces/IVoting.sol";

contract DeployVotingFacet is Script, DiamondHelper {
    function run(address climetaAddress) public {
        VotingFacet votingFacet = new VotingFacet();
        FacetCut[] memory cut = new FacetCut[](1);

        cut[0] = FacetCut ({
            facetAddress: address(votingFacet),
            action: FacetCutAction.Add,
            functionSelectors: generateSelectors("VotingFacet")
        });

        IDiamondCut climeta = IDiamondCut(climetaAddress);

        bytes memory data = abi.encodeWithSignature("init()");
        climeta.diamondCut(cut, address(votingFacet), data);
        climeta.diamondSetInterface(type(IVoting).interfaceId, true);
    }
}
