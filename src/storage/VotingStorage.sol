// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

library VotingStorage {
    struct VotingStruct {
        uint256 votingRound;
        uint256 nextProposalId;
        uint256 votingRoundReward;

        // for each charity address, store all the amounts available  to withdraw
        mapping(address => mapping(address => uint256)) erc20Withdrawls;
        // for each Token, store all the individual donations
        mapping(address => mapping(address => uint256)) erc20Donations;
        mapping(address => uint256) tokenBalances;
        // ETH send to projects
        uint256 totalETHToProjects;
        // list of charity addresses and their ETH balances
        mapping(address => uint256) totalTokenToProjects;

        // proposal id and its metadata uri
        mapping(uint256 => string) proposals;
        mapping(uint256 => address) proposalOwner;
        address[] allowedTokens;

        // Charity address mapping to a mapping of proposals id for that voting round :
        // charity address => voting round => proposals
        mapping(address => mapping(uint256 => uint256)) beneficiaryProposals;
        // List of the accepted proposals in each Voting round
        mapping(uint256 => uint256[]) votingRoundProposals;

        // Votes
        // mapping to show who has already voted in each round. Voting round => Del Mundo => true/false
        mapping(uint256 => mapping(uint256 => bool)) s_votingRoundDelMundoVoters;
        // mapping to show proposal and the membership voting array
        mapping(uint256 => uint256[]) s_votes;

        // Withdrawls
        // Mapping to hold the amounts the beneficiaries can withdraw.
        mapping(address => uint256) s_withdrawls;
        mapping(address => mapping(address => uint256))  s_erc20Withdrawls;
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
