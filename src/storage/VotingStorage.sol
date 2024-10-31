// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library VotingStorage {
    struct VotingStruct {
        uint256 votingRound;
        uint256 nextProposalId;

        // proposal id and its metadata uri
        mapping(uint256 => string) proposals;
        mapping(uint256 => address) proposalOwner;

        // List of the accepted proposals in each Voting round
        mapping(uint256 => uint256[]) votingRoundProposals;
        mapping(uint256 => uint256) proposalVotingRound;

        // Approved charity project addresses
        mapping(address => bool) approvedCharity;

        // Votes
        // mapping to show who has already voted in each round. Voting round => Del Mundo => true/false
        mapping(uint256 => mapping(uint256 => bool)) votingRoundDelMundoVoters;
        // mapping to show proposal and the membership voting array
        mapping(uint256 => uint256[]) votes;

        // Withdrawals
        // Mapping to hold the amounts the beneficiaries can withdraw.
        mapping(address => uint256) withdrawals;
        // charity address => ERC20 => amount
        mapping(address => mapping(address => uint256))  erc20Withdrawals;
    }

    // keccak256(abi.encode(uint256(keccak256("io.climeta.voting")) - 1)) & ~bytes32(uint256(0xff));
    /// @custom:storage-location erc7201:io.climeta.voting
    bytes32 constant VOTINGSTRUCT_POSITION = keccak256(abi.encode(uint256(keccak256("io.climeta.voting")) - 1)) & ~bytes32(uint256(0xff));

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
