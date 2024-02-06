// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ProposalContract {
    address public owner;
    uint256 private counter;
    address[] private voted_addresses;

    mapping(uint256 => Proposal) proposal_history;

    constructor() {
        owner = msg.sender;
        voted_addresses.push(owner);
    }

    struct Proposal {
        string title;
        string description;
        uint256 approve;
        uint256 reject;
        uint256 pass;
        uint256 total_vote_to_end;
        bool current_state;
        bool is_active;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this operation");
        _;
    }

    modifier active(uint256 _counter) {
        require(proposal_history[_counter].is_active, "The proposal is not active");
        _;
    }

    modifier newVoter(address _address) {
        require(!isVoted(_address), "Address has already voted");
        _;
    }

    function create(string calldata _title, string calldata _description, uint256 _total_vote_to_end) external onlyOwner {
        counter++;
        proposal_history[counter] = Proposal(_title, _description, 0, 0, 0, _total_vote_to_end, false, true);
    }

    function setOwner(address new_owner) external onlyOwner {
        owner = new_owner;
    }

    function calculateCurrentState(uint256 _counter) private view returns(bool) {
        Proposal storage proposal = proposal_history[_counter];

        uint256 totalVotes = proposal.approve + proposal.reject + proposal.pass;
        uint256 passThreshold = (proposal.total_vote_to_end / 2) + 1;

        if (totalVotes < proposal.total_vote_to_end) {
            return false; // Proposal hasn't reached the required number of votes yet
        }

        uint256 totalApproveRequired = passThreshold + (proposal.pass % 2);
        uint256 totalRejectRequired = proposal.total_vote_to_end - totalApproveRequired;

        return (proposal.approve >= totalApproveRequired && proposal.reject <= totalRejectRequired);
    }

    function vote(uint8 choice) external {
        Proposal storage proposal = proposal_history[counter];
        uint256 total_vote = proposal.approve + proposal.reject + proposal.pass;

        voted_addresses.push(msg.sender);

        if (choice == 1) {
            proposal.approve++;
            proposal.current_state = calculateCurrentState(counter);
        } else if (choice == 2) {
            proposal.reject++;
            proposal.current_state = calculateCurrentState(counter);
        } else if (choice == 0) {
            proposal.pass++;
            proposal.current_state = calculateCurrentState(counter);
        }

        if ((proposal.total_vote_to_end - total_vote == 1) && (choice == 1 || choice == 2 || choice == 0)) {
            proposal.is_active = false;
            voted_addresses = [owner];
        }
    }

    function teminateProposal() external onlyOwner active(counter) {
        proposal_history[counter].is_active = false;
    }

    function isVoted(address _address) public view returns (bool) {
        for (uint256 i = 0; i < voted_addresses.length; i++) {
            if (voted_addresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getCurrentProposal() external view returns(Proposal memory) {
        return proposal_history[counter];
    }

    function getProposal(uint256 number) external view returns(Proposal memory) {
        return proposal_history[number];
    }
}
