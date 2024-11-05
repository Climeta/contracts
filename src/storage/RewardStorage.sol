// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library RewardStorage {
    struct RewardStruct {
        // member address => amount
        mapping(address => uint256)  claimableRaywards;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.rewards")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.rewards
    bytes32 constant REWARDSTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.rewards")) - 1)) & ~bytes32(uint256(0xff));

    function rewardStorage()
    internal
    pure
    returns (RewardStruct storage rewardstruct)
    {
        bytes32 position = REWARDSTRUCT_POSITION;
        assembly {
            rewardstruct.slot := position
        }
    }
}
