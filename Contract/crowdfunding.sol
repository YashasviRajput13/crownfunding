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
        address[] contributors;
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

    event DeadlineExtended(
        uint256 indexed campaignId,
        uint256 newDeadline
    );

    /**
     * @dev Create a new crowdfunding campaign
     */
    function createCampaign(
        string memory _title,
        string memory _description,
        uint256 _goalAmount,
        uint256 _durationDays
    ) public returns (uint256) {
        require(_goalAmount > 0, "Goal must be > 0");
        require(_durationDays > 0, "Duration must be > 0");
        require(bytes(_title).length > 0, "Title required");
        
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
     */
    function contribute(uint256 _campaignId) public payable {
        require(_campaignId < campaignCount, "No such campaign");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp < campaign.deadline, "Ended");
        require(!campaign.finalized, "Finalized");
        require(msg.value > 0, "Zero value");

        if (campaign.contributions[msg.sender] == 0) {
            campaign.contributors.push(msg.sender);
        }

        campaign.contributions[msg.sender] += msg.value;
        campaign.raisedAmount += msg.value;

        emit ContributionMade(_campaignId, msg.sender, msg.value);
    }

    /**
     * @dev Finalize campaign
     */
    function finalizeCampaign(uint256 _campaignId) public {
        require(_campaignId < campaignCount, "No such campaign");
        Campaign storage campaign = campaigns[_campaignId];
        
        require(block.timestamp >= campaign.deadline, "Still active");
        require(!campaign.finalized, "Already finalized");

        campaign.finalized = true;
        bool successful = campaign.raisedAmount >= campaign.goalAmount;

        uint256 raised = campaign.raisedAmount;

        if (successful) {
            campaign.raisedAmount = 0;
            (bool sent, ) = campaign.creator.call{value: raised}("");
            require(sent, "Transfer failed");
        }

        emit CampaignFinalized(_campaignId, successful, raised);
    }

    /**
     * @dev Claim refund for failed campaign
     */
    function claimRefund(uint256 _campaignId) public {
        require(_campaignId < campaignCount, "No such campaign");
        Campaign storage campaign = campaigns[_campaignId];

        require(campaign.finalized, "Not finalized");
        require(campaign.raisedAmount < campaign.goalAmount, "Campaign success");

        uint256 contribution = campaign.contributions[msg.sender];
        require(contribution > 0, "Nothing to refund");

        campaign.contributions[msg.sender] = 0;
        payable(msg.sender).transfer(contribution);
    }

    /**
     * @dev Extend deadline (only creator)
     */
    function extendDeadline(uint256 _campaignId, uint256 _additionalDays) public {
        require(_campaignId < campaignCount, "No such campaign");
        Campaign storage campaign = campaigns[_campaignId];

        require(msg.sender == campaign.creator, "Not creator");
        require(!campaign.finalized, "Finalized");
        require(_additionalDays > 0, "Invalid extension");
        require(block.timestamp < campaign.deadline, "Already ended");

        campaign.deadline += (_additionalDays * 1 days);

        emit DeadlineExtended(_campaignId, campaign.deadline);
    }

    /**
     * @dev Get campaign details
     */
    function getCampaignDetails(uint256 _campaignId) 
        public 
        view 
        returns (
            address creator,
            string memory title,
            string memory description,
            uint256 goalAmount,
            uint256 raisedAmount,
            uint256 deadline,
            bool finalized,
            uint256 contributorCount
        ) 
    {
        require(_campaignId < campaignCount, "No such campaign");
        Campaign storage campaign = campaigns[_campaignId];

        return (
            campaign.creator,
            campaign.title,
            campaign.description,
            campaign.goalAmount,
            campaign.raisedAmount,
            campaign.deadline,
            campaign.finalized,
            campaign.contributors.length
        );
    }

    /**
     * @dev Get contribution amount
     */
    function getContribution(uint256 _campaignId, address _contributor) public view returns (uint256) {
        require(_campaignId < campaignCount, "No such campaign");
        return campaigns[_campaignId].contributions[_contributor];
    }
}
