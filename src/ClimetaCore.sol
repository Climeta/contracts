// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./token/DelMundo.sol";
import "./token/Rayward.sol";
import "./RayWallet.sol";
import "./ERC6551Registry.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Main Climeta community fund management and voting contract
/// @author matt@climeta.io
/// @notice This will be an upgradeable contract
/// @dev bugbounty contact mysaviour@climeta.io
contract ClimetaCore is Initializable, AccessControlEnumerableUpgradeable {

    // Events
    event ClimetaCore__Payout(address _to, uint256 _amount, uint256 _votingRound);
    event ClimetaCore__Vote(uint256 _votingNFT, uint256 _proposalId);
    event ClimetaCore__NewProposal(address _benefactor, uint256 _proposalId, uint256 timestamp);
    event ClimetaCore__ChangeProposal(address _benefactor, uint256 _proposalId, uint256 timestamp);
    event ClimetaCore__ProposalIncluded(uint256 _votingRound, uint256 _proposalId);
    event ClimetaCore__ProposalExcluded(uint256 _votingRound, uint256 _proposalId);
    event ClimetaCore__NewBeneficiary(address _beneficiary, string name);
    event ClimetaCore__RemovedBeneficiary(address _beneficiary);
    event ClimetaCore__Donation(address _benefactor, uint256 timestamp, uint256 _amount);

    // Errors
    error ClimetaCore__NotAdmin();
    error ClimetaCore__NotAuthContract();
    error ClimetaCore__NotRayWallet();
    error ClimetaCore__NotAMember();
    error ClimetaCore__NotApproved();
    error ClimetaCore__NoProposal();
    error ClimetaCore__AlreadyInRound();
    error ClimetaCore__ProposalNotInRound();
    error ClimetaCore__AlreadyVoted();
    error ClimetaCore__NoVotes();

    // Structures
    struct Proposal {
        uint256 id;
        address beneficiaryAddress;
        string metadataURI;
        uint256 votingRound;
    }

    struct Beneficiary {
        address beneficiaryAddress;
        string name;
        string dataURI;
        bool approved;
    }
    bytes32 public constant CUSTODIAN_ROLE = keccak256("CUSTODIAN_ROLE");

    // Other important contract addresses
    address internal s_delMundoContract;
    address internal s_raywardContract;
    address private s_authorizationContract;
    address private s_rayRegistry;
    address private s_rayWallet;

    // TODO decide what to do if a brand changes address. Do we manage brand as a concept on chain?
    uint256 public s_proposalId;
    uint256 public s_votingRound;

    uint256 public s_totalDonatedAmount;
    mapping(address => uint256) public s_donations;

    mapping(uint256 => Proposal) private s_proposals;
    uint256[] public s_proposalList;

    // Mapping to hold the beneficiary address and the data -
    // TODO do we map charity by an id or by an address?
    mapping(address => Beneficiary) public s_beneficiaries;

    // Charity address mapping to a mapping of proposals id for that voting round : charity address => voting round => proposals
    mapping(address => mapping(uint256 => uint256)) s_beneficiaryProposals;

    // List of the accepted proposals in each Voting round
    mapping(uint256 => uint256[]) public s_votingRoundProposals;

    // mapping to show who has already voted in each round. Voting round => DEl Mundo => true/false
    mapping(uint256 => mapping(uint256 => bool)) s_votingRoundDelMundoVoters;

    // mapping to show proposal and the membership voting array
    mapping(uint256 => uint256[]) s_votes;

    // gap param for storage blocking
    uint256[49] __gap;

    modifier onlyAdmin () {
        if (!hasRole(CUSTODIAN_ROLE, msg.sender)) {
            revert ClimetaCore__NotAdmin();
        }
        _;
    }

    modifier onlyMember () {
        // TODO this seems ugly. must be an easier way to see if msg.sender is a relevant token bound address
        uint32 size;
        uint256 _tokenId;
        address _caller;
        address _addr;
        uint256 _ret;
        _caller = msg.sender;
        // Ensure caller is a smart contract (ie smart wallet for voting)
        assembly {
            size := extcodesize(_caller)
        }
        if (size == 0) {
            revert ClimetaCore__NotRayWallet();
        }
        (_ret, _addr, _tokenId) = RayWallet(payable(_caller)).token();
        // if _tokenId isn't valid and this isn't right chain and not the right contract, then not a valid member token.
        if ((_tokenId <= 0) || (_tokenId > DelMundo(s_delMundoContract).totalSupply()) || (_ret != block.chainid) || (_addr != s_delMundoContract)) {
            revert ClimetaCore__NotAMember();
        }
        _;
    }

    /// @notice Initializer function
    /// @param _adminAddress - address of the initial administrator for the core of Climeta
    /// @param _delMundoAddress Contract address for the DelMundo token
    /// @param _raywardAddress Contract address for the Rayward token
    /// @param _rayRegistryAddress Contract address for the erc6551 Registry
    /// @param _rayWalletAddress Contract address for Ray's Wallet
    function initialize (address _adminAddress, address _delMundoAddress, address _raywardAddress, address _rayRegistryAddress, address _rayWalletAddress) public initializer {
        _grantRole(CUSTODIAN_ROLE, _adminAddress);
        s_delMundoContract = _delMundoAddress;
        s_raywardContract = _raywardAddress;
        s_proposalId = 1;
        s_rayWallet = _rayWalletAddress;
        s_rayRegistry = _rayRegistryAddress;
        s_votingRound = 1;
    }

    receive() external payable {
        if (msg.sender != s_authorizationContract) {
            revert ClimetaCore__NotAuthContract();
        }
    }

    function version() external pure returns (string memory) {
        return "1.0";
    }

    //TODO move into utils library
    function getVoteReward() public pure returns (uint256) {
        return 100;
    }
    function getVoterMultiplier (address voterAddress) internal view returns (uint256) {
        // TODO need to include the voting Rayward multiplier function
        return 1;
    }

    function isAdmin(address _isAdmin) public view returns (bool)  {
        return hasRole(CUSTODIAN_ROLE, _isAdmin);
    }

    function getAdminCount () public view returns(uint256) {
        return getRoleMemberCount(CUSTODIAN_ROLE);
    }

    function updateAuthContract(address _authContract) external onlyAdmin {
        s_authorizationContract = _authContract;
    }

    function addAdmin(address newAdmin) external onlyAdmin {
        _grantRole(CUSTODIAN_ROLE, newAdmin);
    }
    function revokeAdmin(address oldAdmin) public onlyAdmin {
        require (msg.sender != oldAdmin, "Can't revoke yourself");
        _revokeRole(CUSTODIAN_ROLE, oldAdmin);
    }

    // Beneficiary Administration
    // TODO decide if a charity is defined by its wallet address or its name
    function addBeneficiary(address _beneficiary, string calldata _name, string calldata _dataURI) public onlyAdmin {
        require(bytes(_name).length > 0, "Name cannot be empty" );
        s_beneficiaries[_beneficiary].name = _name;
        s_beneficiaries[_beneficiary].approved = true;
        s_beneficiaries[_beneficiary].dataURI = _dataURI;
        emit ClimetaCore__NewBeneficiary(_beneficiary, _name);
    }
    // TODO decide on whether we ever remove a charity
    function removeBeneficiary(address _beneficiary) external onlyAdmin {
        if (s_beneficiaries[_beneficiary].approved == true) {
            s_beneficiaries[_beneficiary].approved = false;
            s_beneficiaries[_beneficiary].name = "";
            emit ClimetaCore__RemovedBeneficiary(_beneficiary);
        }
    }
    function isBeneficiary (address _beneficiary) external view returns (bool) {
        return (s_beneficiaries[_beneficiary].approved == true);
    }

    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return s_proposals[proposalId];
    }

    // Allow the adding of proposals by the Admin group only
    function addProposal(address _beneficiary, string calldata _proposalURI) external onlyAdmin {
        if (s_beneficiaries[_beneficiary].approved == false) {
            revert ClimetaCore__NotApproved();
        }
        uint256 m_proposalId = s_proposalId;
        s_proposals[m_proposalId] = Proposal(m_proposalId, _beneficiary, _proposalURI, 0);
        s_proposalList.push(m_proposalId);
        emit ClimetaCore__NewProposal(_beneficiary, m_proposalId, block.timestamp);
        s_proposalId++;
    }

    function getAllProposals() external view returns (uint256[] memory) {
        return s_proposalList;
    }

    function updateProposal(uint256 _propId, string calldata _proposalURI) external onlyAdmin {
        if (s_proposals[_propId].id == 0) {
            revert ClimetaCore__NoProposal();
        }
        s_proposals[_propId].metadataURI = _proposalURI;
    }

    function addProposalToVotingRound (uint256 _proposalId) external onlyAdmin {
        if (s_proposals[_proposalId].id == 0) {
            revert ClimetaCore__NoProposal();
        }
        if (s_proposals[_proposalId].votingRound != 0) {
            revert ClimetaCore__AlreadyInRound();
        }
        uint256 m_votingRound = s_votingRound;
        // Mark the proposal as in the current voting round
        s_proposals[_proposalId].votingRound = m_votingRound;
        // Add the proposal to the votingRound list
        s_votingRoundProposals[m_votingRound].push(_proposalId);
        emit ClimetaCore__ProposalIncluded(m_votingRound, _proposalId);
    }

    function removeProposalFromVotingRound (uint256 _proposalId) external onlyAdmin {
        uint256 m_votingRound = s_votingRound;
        if (s_proposals[_proposalId].votingRound != m_votingRound) {
            revert ClimetaCore__ProposalNotInRound();
        }
        s_proposals[_proposalId].votingRound = 0;
        uint256 numberOfProposals = s_votingRoundProposals[m_votingRound].length;
        // remove from array of proposals for this voting round
        for (uint256 i=0; i < numberOfProposals;i++) {
            if (s_votingRoundProposals[m_votingRound][i] == _proposalId) {
                for (uint256 j=i; j < numberOfProposals -1 ; j++ ) {
                    s_votingRoundProposals[m_votingRound][j] = s_votingRoundProposals[m_votingRound][j+1];
                }
                s_votingRoundProposals[m_votingRound].pop();
                emit ClimetaCore__ProposalExcluded(m_votingRound, _proposalId);
                return;
            }
        }
    }

    // get list of proposal ids for this voting round
    function getProposalsThisRound() external view returns (uint256[] memory){
        return s_votingRoundProposals[s_votingRound];
    }

    function hasVoted(uint256 _tokenId) external view returns(bool) {
        return s_votingRoundDelMundoVoters[s_votingRound][_tokenId];
    }

    function castVote(uint256 _propId) external onlyMember {
        // require proposal to be part of voting _votingRound
        uint256 m_votingRound = s_votingRound;
        if (s_proposals[_propId].votingRound != m_votingRound) {
            revert ClimetaCore__ProposalNotInRound();
        }
        // Get the token related to the caller
        uint256 _tokenId;
        address _addr;
        uint256 _ret;
        (_ret, _addr, _tokenId) = RayWallet(payable(msg.sender)).token();

        // Ensure not already voted
        if (s_votingRoundDelMundoVoters[m_votingRound][_tokenId] == true) {
            revert ClimetaCore__AlreadyVoted();
        }

        // Add vote to vote history mapping to ensure single vote
        s_votingRoundDelMundoVoters[m_votingRound][_tokenId] = true;
        s_votes[_propId].push(_tokenId);

        // Send Raywards
        uint256 rewardAmount = getVoteReward();
        Rayward(s_raywardContract).transferFrom(s_rayWallet, msg.sender, rewardAmount * getVoterMultiplier(msg.sender));
        emit ClimetaCore__Vote(_tokenId, _propId);
    }

    function endVotingRound () external payable onlyAdmin {
        uint256 totalVotes = 0;
        uint256 m_votingRound = s_votingRound;
        uint256[] memory propIds = s_votingRoundProposals[m_votingRound];
        uint256 propIdsLength = propIds.length;

        // find total number of votes for this round and mark proposals as non active now.
        for (uint256 i = 0; i < propIdsLength; i++) {
            totalVotes += s_votes[propIds[i]].length;
        }
        if (totalVotes == 0) {
            revert ClimetaCore__NoVotes();
        }

        // TODO will need a failsafe here in case anything fails. Might need to enable a withdraw function instead
        // TODO need to add in the 10% across all proposals
        // This also needs to mark each one as complete so if rerun they don't get paid twice.
        uint256 fundBalance = address(this).balance;

        // need to send out the 10% to all
        uint256 toAll = (fundBalance * 10) / (propIdsLength*100);

        // amount paid out is % of fund to each beneficiary
        for (uint256 i = 0; i < propIdsLength; i++) {
            uint256 amount;
            unchecked {amount = (fundBalance * 90 * s_votes[propIds[i]].length/totalVotes)/100 + toAll;}
            payable( s_proposals[propIds[i]].beneficiaryAddress).call{value: amount}("");
            emit ClimetaCore__Payout(s_proposals[propIds[i]].beneficiaryAddress, fundBalance * s_votes[propIds[i]].length/totalVotes, m_votingRound);
        }
        s_votingRound++;
    }

    function getTotalDonatedFunds() external view returns (uint256) {
        return s_totalDonatedAmount;
    }

    function getTotalDonationsByAddress(address _address) external view returns (uint256) {
        return s_donations[_address];
    }

    function getVotesForProposal(uint256 _propId) external view returns (uint256[] memory) {
        return s_votes[_propId];
    }

    function donate(address _benefactor) payable external {
        require(msg.sender == s_authorizationContract, "Please donate via Authorization contract");
        s_totalDonatedAmount += msg.value;
        s_donations[_benefactor] += msg.value;
        emit ClimetaCore__Donation(_benefactor, block.timestamp, msg.value);
    }


}
