// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

library RayValues {

    function getVoteReward() public pure returns (uint256) {
        return 1000;
    }

    function getVoterMultiplier (address voterAddress) internal view returns (uint256) {
        // TODO need to include the voting Rayward multiplier function
        // Deal with someone having 0 Rayward - ie a RayDelMundo transfer. They should get a single vote and then earn
        // uint256 balanceRayward = RaywardToken.balanceOf(voterAddress);
        // X votes = log2(balanceRayward+1)

        return 1;
    }
}
