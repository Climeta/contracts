// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./token/DelMundo.sol";
import "./token/Rayward.sol";
import "./RayWallet.sol";
import "@tokenbound/erc6551/ERC6551Registry.sol";
import "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title Main Climeta community fund management and voting contract
/// @author matt@climeta.io
/// @notice This will be an upgradeable contract
/// @dev bugbounty contact mysaviour@climeta.io
contract ClimetaCore is Initializable, AccessControlEnumerableUpgradeable, ReentrancyGuard {

    // Events
    /// @notice Emitted when a payout is made
    /// @param _to The address receiving the payout
    /// @param _amount The amount of the payout
    event ClimetaCore__Payout(address _to, uint256 _amount);

    /// @notice Emitted when a vote is cast
    /// @param _votingNFT The NFT used to vote
    /// @param _proposalId The ID of the proposal being voted on
    event ClimetaCore__Vote(uint256 _votingNFT, uint256 _proposalId);

    /// @notice Emitted when a new proposal is added
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the new proposal
    /// @param timestamp The time when the proposal was added
    event ClimetaCore__NewProposal(address _benefactor, uint256 _proposalId, uint256 timestamp);

    /// @notice Emitted when a proposal is changed
    /// @param _benefactor The address of the benefactor
    /// @param _proposalId The ID of the proposal being changed
    /// @param timestamp The time when the proposal was changed
    event ClimetaCore__ChangeProposal(address _benefactor, uint256 _proposalId, uint256 timestamp);

    /// @notice Emitted when a proposal is included in a voting round
    /// @param _votingRound The voting round in which the proposal was included
    /// @param _proposalId The ID of the proposal being included
    event ClimetaCore__ProposalIncluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a proposal is excluded from a voting round
    /// @param _votingRound The voting round from which the proposal was excluded
    /// @param _proposalId The ID of the proposal being excluded
    event ClimetaCore__ProposalExcluded(uint256 _votingRound, uint256 _proposalId);

    /// @notice Emitted when a new beneficiary is added
    /// @param _beneficiary The address of the new beneficiary
    /// @param name The name of the new beneficiary
    event ClimetaCore__NewBeneficiary(address _beneficiary, string name);

    /// @notice Emitted when a beneficiary is removed
    /// @param _beneficiary The address of the beneficiary being removed
    event ClimetaCore__RemovedBeneficiary(address _beneficiary);

    /// @notice Emitted when a donation is made
    /// @param _benefactor The address of the benefactor making the donation
    /// @param timestamp The time when the donation was made
    /// @param _amount The amount of the donation
    event ClimetaCore__Donation(address _benefactor, uint256 timestamp, uint256 _amount);

    // Errors
    error ClimetaCore__CannotRemoveLastAdmin();
    error ClimetaCore__NotAdmin();
    error ClimetaCore__NotRayWallet();
    error ClimetaCore__NotAMember();
    error ClimetaCore__NotApproved();
    error ClimetaCore__NoProposal();
    error ClimetaCore__AlreadyInRound();
    error ClimetaCore__ProposalNotInRound();
    error ClimetaCore__AlreadyVoted();
    error ClimetaCore__NoVotes();
    error ClimetaCore__NotFromAuthContract();

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
    bytes32 public constant CUSTODIAN_ADMIN_ROLE = keccak256("CUSTODIAN_ADMIN_ROLE");
    uint64 public constant EVERYONE_PERCENTAGE = 10;

    // Other important contract addresses
    address internal s_delMundoContract;
    address internal s_raywardContract;
    address private s_authorizationContract;
    address private s_rayRegistry;
    address private s_rayWallet;

    // TODO decide what to do if a brand changes address. Do we manage brand as a concept on chain?
    uint256 public s_proposalId;
    uint256 public s_votingRound;
    uint256 public s_voteReward;

    uint256 public s_totalDonatedAmount;
    mapping(address => uint256) public s_donations;

    mapping(uint256 => Proposal) private s_proposals;
    uint256[] public s_proposalList;

    // Mapping to hold the amounts the beneficiaries can withdraw.
    mapping(address => uint256) s_withdrawls;

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

    /// @notice Modifier to ensure only admins can call a function
    modifier onlyAdmin () {
        if (!hasRole(CUSTODIAN_ROLE, msg.sender)) {
            revert ClimetaCore__NotAdmin();
        }
        _;
    }

    /** @dev Initialiser for the main voting contract for Climeta. This assigns all the important references that the voting contract interacts with during the voting flow
     *
     * We initiate some of the counters here, like the proposal id and the voting round. Access control is granted to an initial admin and we grant the ability to do ongoing grants with the role itself,
     * so Admin curation is not seperate from the rest of Admin activity. No role segregation here.
     *
     * @param _adminAddress - address of the initial administrator for the core of Climeta.
     * @param _delMundoAddress Contract address for the DelMundo token
     * @param _raywardAddress Contract address for the Rayward token
     * @param _rayRegistryAddress Contract address for the erc6551 Registry so we can look up and verify Del Mundo ownership
     * @param _rayWalletAddress Contract address for Ray's Wallet which is in effect the reward pool for Climeta.
     */
    function initialize (address _adminAddress, address _delMundoAddress, address _raywardAddress, address _rayRegistryAddress, address _rayWalletAddress) public initializer {
        _grantRole(CUSTODIAN_ROLE, _adminAddress);
        _grantRole(CUSTODIAN_ADMIN_ROLE, _adminAddress);
        _setRoleAdmin(CUSTODIAN_ROLE, CUSTODIAN_ADMIN_ROLE);
        s_delMundoContract = _delMundoAddress;
        s_raywardContract = _raywardAddress;
        s_proposalId = 1;
        s_rayWallet = _rayWalletAddress;
        s_rayRegistry = _rayRegistryAddress;
        s_votingRound = 1;
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    /// @dev This function will change when the implementation changes
    function version() external pure returns (string memory) {
        return "1.0";
    }

    /// @notice Sets the amount of raywards given for voting. Can only be called by Admins
    /// @param _reward The new reward amount
    function setVoteReward(uint256 _reward) public onlyAdmin {
        s_voteReward = _reward;
    }

    /// @notice Returns the multiplier for a voter
    /// @param _delMundoId The tokenId of the del Mundo of the voter
    /// @return The multiplier for the voter
    function getVoterMultiplier (uint256 _delMundoId) internal view returns (uint256) {
        // TODO need to include the Rayputation multiplier function
        return 1;
    }

    /// @notice Checks if an address is an admin
    /// @param _isAdmin The address to check
    /// @return True if the address is an admin, false otherwise
    function isAdmin(address _isAdmin) public view returns (bool)  {
        return hasRole(CUSTODIAN_ROLE, _isAdmin);
    }

    /// @notice Returns the count of admins
    /// @return The count of admins
    function getAdminCount () public view returns(uint256) {
        return getRoleMemberCount(CUSTODIAN_ROLE);
    }

    /// @notice Updates the authorization contract
    /// @param _authContract The address of the new authorization contract
    function updateAuthContract(address _authContract) external onlyAdmin {
        s_authorizationContract = _authContract;
    }

    /// @notice Adds a new admin
    /// @param newAdmin The address of the new admin
    function addAdmin(address newAdmin) external onlyAdmin {
        _grantRole(CUSTODIAN_ROLE, newAdmin);
        _grantRole(CUSTODIAN_ADMIN_ROLE, newAdmin);
    }

    /// @notice Revokes an admin
    /// @param oldAdmin The address of the admin to remove
    function revokeAdmin(address oldAdmin) public onlyAdmin {
        if (getAdminCount() == 1) {
            revert ClimetaCore__CannotRemoveLastAdmin();
        }
        _revokeRole(CUSTODIAN_ROLE, oldAdmin);
        _revokeRole(CUSTODIAN_ADMIN_ROLE, oldAdmin);
    }

    // Beneficiary Administration

    /// @notice Adds a new beneficiary
    /// @param _beneficiary The address of the new beneficiary
    /// @param _name The name of the new beneficiary
    /// @param _dataURI The URI of the data associated with the new beneficiary
    function addBeneficiary(address _beneficiary, string calldata _name, string calldata _dataURI) public onlyAdmin {
        require(bytes(_name).length > 0, "Name cannot be empty" );
        s_beneficiaries[_beneficiary].name = _name;
        s_beneficiaries[_beneficiary].approved = true;
        s_beneficiaries[_beneficiary].dataURI = _dataURI;
        emit ClimetaCore__NewBeneficiary(_beneficiary, _name);
    }

    /// @notice Removes a beneficiary
    /// @param _beneficiary The address of the beneficiary to remove
    function removeBeneficiary(address _beneficiary) external onlyAdmin {
        if (s_beneficiaries[_beneficiary].approved == true) {
            s_beneficiaries[_beneficiary].approved = false;
            s_beneficiaries[_beneficiary].name = "";
            emit ClimetaCore__RemovedBeneficiary(_beneficiary);
        }
    }
    /// @notice checks if the address is a registered and approved beneficiary
    /// @param _beneficiary The address to check
    /// @return True if the address is a beneficiary, false otherwise
    function isBeneficiary (address _beneficiary) external view returns (bool) {
        return (s_beneficiaries[_beneficiary].approved == true);
    }

    /// @notice Gets the proposal details
    /// @param proposalId The address of the new beneficiary
    /// @return The proposal struct for that id
    function getProposal(uint256 proposalId) external view returns (Proposal memory) {
        return s_proposals[proposalId];
    }

    // Allow the adding of proposals by the Admin group only
    /// @notice Adds a new beneficiary
    /// @param _beneficiary The address of the new beneficiary
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

    /// @notice Returns the submitted proposal id array
    /// @return an array of all the proposal ids, irrespective of status or history
    function getAllProposals() external view returns (uint256[] memory) {
        return s_proposalList;
    }

    /// @notice Updates a proposa;
    /// @param _propId The proposal ID to update
    /// @param _proposalURI new URI of the proposal
    function updateProposal(uint256 _propId, string calldata _proposalURI) external onlyAdmin {
        if (s_proposals[_propId].id == 0) {
            revert ClimetaCore__NoProposal();
        }
        s_proposals[_propId].metadataURI = _proposalURI;
    }

    /**
    * @dev Proposals are submitted by the beneficiaries and then added to the voting round by the Admins
    * This is managed in 2 places on chain, the s_votingRoundProposals which is a mapping of the voting round to an array of prpoposals
    * and the s_proposals mapping which has the voting round the proposal is in stored directly against the proposal struct itself.
    *
    * @param _proposalId The ID of the proposal to add
    */
    function addProposalToVotingRound (uint256 _proposalId) external onlyAdmin {
        if (s_proposals[_proposalId].id == 0) {
            revert ClimetaCore__NoProposal();
        }
        if (s_proposals[_proposalId].votingRound != 0) {
            revert ClimetaCore__AlreadyInRound();
        }
        // pull from storage once
        uint256 m_votingRound = s_votingRound;
        // Mark the proposal as in the current voting round
        s_proposals[_proposalId].votingRound = m_votingRound;
        // Add the proposal to the votingRound list
        s_votingRoundProposals[m_votingRound].push(_proposalId);
        emit ClimetaCore__ProposalIncluded(m_votingRound, _proposalId);
    }

    /**
    * @dev Removal from voting round will be an exception use case, hence the less gas effective manner of removing as opposed to adding.
    * The bulk of the work is in removing from the proposal array for the voting round, but this array will only really be a handful of
    * proposals each time, it is not an unbounded array as such.
    *
    * @param _proposalId The ID of the proposal to remove
    */
    function removeProposalFromVotingRound (uint256 _proposalId) external onlyAdmin {
        // retrieve from storage once
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

    /**
    * @dev This is the core interaction in Climeta. The vote. We need to ensure that only members vote and that they can only vote once.
    * This function needs to be called by the wallet of the Del Mundo, not by the end user.
    *
    * The membership test gets the tokenid associated with the calling wallet and then validates chain, right del mundo contract
    * and that the tokenid is in the right range. We also ensure that the caller is a smart contract, not an end user wallet as first check.
    *
    * The rewards for voting are also directly sent out via this contract function to the caller. This contract has the permissions
    * and the allowances setup to send from Ray's wallet which holds the reward pool of Raywards.
    *
    * We also need to ensure that the proposal is in the current voting round.
    *
    * Votes are stored in a couple of places. We store the full list of del mundo token ids that have voted for each proposal
    * as well as a lookup mapping of voting round to del mundo to boolean as a quick check to avoid array lookups.
    *
    * Voting currently is an immutable operation, there is no undoing once voted.
    *
    * @param _propId The ID of the proposal to vote on
    */
    function castVote(uint256 _propId) external {
        uint256 m_votingRound = s_votingRound;
        // require proposal to be part of voting _votingRound
        if (s_proposals[_propId].votingRound != m_votingRound) {
            revert ClimetaCore__ProposalNotInRound();
        }

        // Membership test
        uint32 size;
        uint256 _tokenId;
        address _addr;
        uint256 _ret;
        address _caller = msg.sender;
        // Ensure caller is a smart contract (eg smart wallet for voting)
        assembly {
            size := extcodesize(_caller)
        }
        if (size == 0) {
            revert ClimetaCore__NotRayWallet();
        }
        (_ret, _addr, _tokenId) = RayWallet(payable(_caller)).token();
        // if _tokenId isn't valid (in range) and this isn't right chain and not the right contract, then not a valid member token.
        // Also, Ray himself (tokenId == 0) can't vote.
        if ((_tokenId <= 0) || (_tokenId > DelMundo(s_delMundoContract).totalSupply()) || (_ret != block.chainid) || (_addr != s_delMundoContract)) {
            revert ClimetaCore__NotAMember();
        }

        // Ensure not already voted
        if (s_votingRoundDelMundoVoters[m_votingRound][_tokenId] == true) {
            revert ClimetaCore__AlreadyVoted();
        }

        // Add vote to vote history mapping and mark as voted to ensure single vote
        s_votingRoundDelMundoVoters[m_votingRound][_tokenId] = true;
        s_votes[_propId].push(_tokenId);

        // Send Raywards
        Rayward(s_raywardContract).transferFrom(s_rayWallet, _caller, s_voteReward * getVoterMultiplier(_tokenId));
        emit ClimetaCore__Vote(_tokenId, _propId);
    }

    /**
    * @dev The ending of a voting round is a manual action perfomed by Climeta Admins. This may change moving forwards to be more autonomous.
    *
    * The fund is currently split into 2 pieces. The EVERYONE_PERCENTAGE ensures that ALL beneficiaries receive an even split of this percentage.
    * This is currently set to 10% at time of writing. The remaining 90% is then split based on the number of votes each proposal received.
    *
    * The actual funds are not actually sent out from this function though. What we do is add in what each beneficiary can withdraw
    * and add this to the s_withdrawls mapping. This is then pulled out by the beneficiary themselves. There is also an admin only function
    * which allows Climeta to push the funds individually from this contract to the beneficiary as a failsafe.
    *
    * The whole fund amount is allocated at this point, there should be nothing left.
    *
    * Going forwards this will become less centralised and more automated via timeboxing and other mechanisms, but for now
    * is fully under the control of Climeta.
    *
    * Once the voting round is concluded, the voting round counter is incremented and we begin again.
    *
    */
    function endVotingRound () external payable onlyAdmin nonReentrant {
        uint256 totalVotes = 0;
        uint256 m_votingRound = s_votingRound;
        uint256[] memory propIds = s_votingRoundProposals[m_votingRound];
        uint256 propIdsLength = propIds.length;

        // find total number of votes for this round
        for (uint256 i = 0; i < propIdsLength; i++) {
            totalVotes += s_votes[propIds[i]].length;
        }
        if (totalVotes == 0) {
            revert ClimetaCore__NoVotes();
        }

        uint256 fundBalance = address(this).balance;
        // work out amount to send out to all according to EVERYONE_PERCENTAGE
        uint256 toAll = (fundBalance * EVERYONE_PERCENTAGE) / (propIdsLength*100);

        // amount paid out is % of fund to each beneficiary
        // Total = amount everyone gets + remainder according to what % of the total vote this proposal received
        for (uint256 i = 0; i < propIdsLength; i++) {
            uint256 amount;
            unchecked {amount = (fundBalance * (100-EVERYONE_PERCENTAGE) * s_votes[propIds[i]].length/totalVotes)/100 + toAll;}
            // Add to amount in case beneficiary has not withdrawn from previous rounds.
            s_withdrawls[s_proposals[propIds[i]].beneficiaryAddress] += amount;
        }
        s_votingRound++;
    }

    /**
    * @dev Allows beneficaries to claim their funds
    * This only allows the owner of the beneficiary address to withdraw the funds.
    *
    */
    function withdraw() external {
        uint256 amount = s_withdrawls[msg.sender];
        s_withdrawls[msg.sender] = 0;
        emit ClimetaCore__Payout(msg.sender, amount);
        payable(msg.sender).call{value: amount}("");
    }

    /**
    * @dev Allows Climeta admins to push the funds directly to the beneficaries
    * This is really for those beneficiaries that may not be able to withdraw themselves for whatever reason.
    * This does not give Cliemta access to the voting funds, once marked as vote end, the only place the funds can go
    * is to the beneficiary.
    *
    * @param _beneficiary The ID of the proposal to vote on
    */
    function pushPayment(address _beneficiary) external onlyAdmin nonReentrant {
        uint256 amount = s_withdrawls[_beneficiary];
        s_withdrawls[_beneficiary] = 0;
        emit ClimetaCore__Payout(_beneficiary, amount);
        payable(_beneficiary).call{value: amount}("");
    }

    function getWithdrawAmount(address _beneficiary) external view returns(uint256) {
        return s_withdrawls[_beneficiary];
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

    /**
    * @dev Donations should only come from approved sources. There is no receive or fallback for that very purpose. Each donation
    * is vertting via the Authorisation contract as we do not accept donations from just anyone.
    * Yes we accept that if someone self destructs a contract, the funds will get wrapped up and distributed to the projects
    * but it will not be registered as a formal donation, the funds will just get sent out anonymously and not tracked.
    *
    * Each donation is logged formally for tracking and transparency as a key component of fund flow. An event is emitted
    * so these can be tracked off chain too.
    *
    * @param _benefactor The ID of the donator.
    */
    function donate(address _benefactor) payable external {
        if (msg.sender != s_authorizationContract) {
            revert ClimetaCore__NotFromAuthContract();
        }
        s_totalDonatedAmount += msg.value;
        s_donations[_benefactor] += msg.value;
        emit ClimetaCore__Donation(_benefactor, block.timestamp, msg.value);
    }


}
