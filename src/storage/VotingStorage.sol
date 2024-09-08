// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library VotingStorage {
    /// @custom:storage-location erc7201:io.climeta.voting
    struct VotingStruct {
        uint var1;
        bytes var2;
        mapping (address => uint) var3;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.voting")) - 1)) & ~bytes32(uint256(0xff));
    bytes32 constant VOTINGSTRUCT_POSITION = 0xfb51f3de952f17d89b384eff8bbf080a8a782750ddcd78fbff0c1a715b8d9800;

    function votingStorage()
    internal
    pure
    returns (VotingStruct storage votingstruct)
    {
        bytes32 position = VOTINGSTRUCT_POSITION;
        assembly {
            votingstruct.slot := position
        }
    }
}
