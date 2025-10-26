// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CrowdChain - Crowdfunding
 * @dev A decentralized crowdfunding platform smart contract
 */
contract Crowdfunding {
    
    struct Campaign {
        address payable creator;
        string title;
        string description;
        uint256 goalAmount;
        uint256 raisedAmount;
        uint256 deadline;
        bool finalized;
        mapping(address => uint256) contributions;
    }
    
    mapping(uint256 => Campaign) public campaigns;
    uint256 public campaignCount;
    
    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creator,
        string title,
        uint256 goalAmount,
        uint256 deadline
    );
    
    event ContributionMade(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );
    
    event CampaignFinalized(
        uint256 indexed campaignId,
        bool successful,
        uint256 totalRaised
    );
    
    /**
     * @dev Create a new crowdfunding campaign
     * @param _title Campaign title
     * @param _description Campaign description
     * @param _goalAmount Target amount to raise (in wei)
     * @param _durationDays Campaign duration in days
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationDays
    ) public returns (uint256) {
        require(_goalAmount > 0, "Goal amount must be greater than 0");
        require(_durationDays > 0, "Duration must be greater than 0");
        require(bytes(_title).length > 0, "Title cannot be empty");
        
        uint256 campaignId = campaignCount++;
        Campaign storage newCampaign = campaigns[campaignId];
        
        newCampaign.creator = payable(msg.sender);
        newCampaign.title = _title;
        newCampaign.description = _description;
        newCampaign.goalAmount = _goalAmount;
        newCampaign.raisedAmount = 0;
        newCampaign.deadline = block.timestamp + (_durationDays * 1 days);
        newCampaign.finalized = false;
        
        emit CampaignCreated(
            campaignId,
            msg.sender,
            _title,
            _goalAmount,
            newCampaign.deadline
        );
        
        return campaignId;
    }
    
    /**
     * @dev Contribute to a campaign
     * @param _campaignId ID of the campaign to contribute to
     */
    function contribute(uint256 _campaignId) public payable {
        require(_campaignId < campaignCount, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        require(!campaign.finalized, "Campaign already finalized");
        require(msg.value > 0, "Contribution must be greater than 0");
        
        campaign.contributions[msg.sender] += msg.value;
        campaign.raisedAmount += msg.value;
        
        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }
    
    /**
     * @dev Finalize a campaign and distribute funds or refund contributors
     * @param _campaignId ID of the campaign to finalize
     */
    function finalizeCampaign(uint256 _campaignId) public {
        require(_campaignId < campaignCount, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Campaign is still active");
        require(!campaign.finalized, "Campaign already finalized");
        
        campaign.finalized = true;
        bool successful = campaign.raisedAmount >= campaign.goalAmount;
        
        if (successful) {
            // Transfer funds to campaign creator
            uint256 amount = campaign.raisedAmount;
            campaign.raisedAmount = 0;
            campaign.creator.transfer(amount);
        }
        // If unsuccessful, contributors can claim refunds individually
        
        emit CampaignFinalized(_campaignId, successful, campaign.raisedAmount);
    }
    
    /**
     * @dev Claim refund if campaign failed
     * @param _campaignId ID of the campaign to claim refund from
     */
    function claimRefund(uint256 _campaignId) public {
        require(_campaignId < campaignCount, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(campaign.finalized, "Campaign not finalized yet");
        require(campaign.raisedAmount < campaign.goalAmount, "Campaign was successful");
        
        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "No contribution to refund");
        
        campaign.contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contribution);
    }
    
    /**
     * @dev Get campaign details
     * @param _campaignId ID of the campaign
     */
    function getCampaignDetails(uint256 _campaignId) public view returns (
        address creator,
        string memory title,
        string memory description,
        uint256 goalAmount,
        uint256 raisedAmount,
        uint256 deadline,
        bool finalized
    ) {
        require(_campaignId < campaignCount, "Campaign does not exist");
        Campaign storage campaign = campaigns[_campaignId];
        
        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.finalized
        );
    }
    
    /**
     * @dev Get contribution amount for a specific address
     * @param _campaignId ID of the campaign
     * @param _contributor Address of the contributor
     */
    function getContribution(uint256 _campaignId, address _contributor) public view returns (uint256) {
        require(_campaignId < campaignCount, "Campaign does not exist");
        return campaigns[_campaignId].contributions[_contributor];
    }
}
