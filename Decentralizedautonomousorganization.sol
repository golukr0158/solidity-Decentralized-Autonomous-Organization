// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Project {
    // State variables
    address public owner;
    uint256 public proposalCount;
    uint256 public constant VOTING_PERIOD = 7 days;
    uint256 public constant MINIMUM_QUORUM = 10; // Minimum votes required
    
    // Governance token balances
    mapping(address => uint256) public governanceTokens;
    uint256 public totalSupply;
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        string description;
        address proposer;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    // Storage
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public members;
    address[] public memberList;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, string description, address indexed proposer);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed proposalId);
    event MemberAdded(address indexed member);
    event TokensIssued(address indexed to, uint256 amount);
    
    // Modifiers
    modifier onlyMember() {
        require(members[msg.sender], "Not a DAO member");
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        members[msg.sender] = true;
        memberList.push(msg.sender);
        governanceTokens[msg.sender] = 100; // Initial tokens for founder
        totalSupply = 100;
        emit MemberAdded(msg.sender);
        emit TokensIssued(msg.sender, 100);
    }
    
    // Core Function 1: Create Proposal
    function createProposal(string memory _description) external onlyMember returns (uint256) {
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(governanceTokens[msg.sender] >= 5, "Insufficient tokens to create proposal");
        
        proposalCount++;
        uint256 proposalId = proposalCount;
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.description = _description;
        newProposal.proposer = msg.sender;
        newProposal.deadline = block.timestamp + VOTING_PERIOD;
        newProposal.executed = false;
        
        emit ProposalCreated(proposalId, _description, msg.sender);
        return proposalId;
    }
    
    // Core Function 2: Vote on Proposal
    function vote(uint256 _proposalId, bool _support) external onlyMember {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(governanceTokens[msg.sender] > 0, "No voting power");
        
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp < proposal.deadline, "Voting period ended");
        require(!proposal.hasVoted[msg.sender], "Already voted");
        
        uint256 votingPower = governanceTokens[msg.sender];
        proposal.hasVoted[msg.sender] = true;
        
        if (_support) {
            proposal.forVotes += votingPower;
        } else {
            proposal.againstVotes += votingPower;
        }
        
        emit VoteCast(_proposalId, msg.sender, _support, votingPower);
    }
    
    // Core Function 3: Execute Proposal
    function executeProposal(uint256 _proposalId) external returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal storage proposal = proposals[_proposalId];
        require(block.timestamp >= proposal.deadline, "Voting period not ended");
        require(!proposal.executed, "Proposal already executed");
        
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        require(totalVotes >= MINIMUM_QUORUM, "Minimum quorum not reached");
        require(proposal.forVotes > proposal.againstVotes, "Proposal rejected");
        
        proposal.executed = true;
        emit ProposalExecuted(_proposalId);
        
        return true;
    }
    
    // Additional helper functions
    function addMember(address _newMember) external onlyOwner {
        require(!members[_newMember], "Already a member");
        require(_newMember != address(0), "Invalid address");
        
        members[_newMember] = true;
        memberList.push(_newMember);
        governanceTokens[_newMember] = 10; // Initial tokens for new members
        totalSupply += 10;
        
        emit MemberAdded(_newMember);
        emit TokensIssued(_newMember, 10);
    }
    
    function getProposalDetails(uint256 _proposalId) external view returns (
        string memory description,
        address proposer,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 deadline,
        bool executed
    ) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        Proposal storage proposal = proposals[_proposalId];
        
        return (
            proposal.description,
            proposal.proposer,
            proposal.forVotes,
            proposal.againstVotes,
            proposal.deadline,
            proposal.executed
        );
    }
    
    function getMemberCount() external view returns (uint256) {
        return memberList.length;
    }
    
    function hasVoted(uint256 _proposalId, address _voter) external view returns (bool) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        return proposals[_proposalId].hasVoted[_voter];
    }
    
    function getVotingPower(address _member) external view returns (uint256) {
        return governanceTokens[_member];
    }
}
