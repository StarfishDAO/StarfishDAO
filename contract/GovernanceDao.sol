pragma solidity ^0.8.0;
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './interface/IGovernanceDao.sol';
import './Impeach.sol';
contract GovernanceDao  is IGovernanceDao{
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;
    uint public tokenProposalCount;
    struct tokenProposal{
        uint id;
        address owner;
        uint stage;
        uint day;
        uint applyAmount;
        uint depositAmount;
        uint opposeTickets;
        string  description;
        uint parliamentsAgree;
        uint creationTime;
        uint voteStartTime;
        mapping(uint => stageDetails) everyStageDetails;
    }
    struct stageDetails {
        bool start;
        uint oppose;
        bool received;
        bool canSubmit;
        uint startTime;
        uint againSecond;
        string  description;
    }
    struct Governance {
        uint expireBlock;
        uint voteId;
        bool votePeriod;
        uint impeachIndex;
        uint proposalBlockNumber;
        address govToken;
        bool firstActive;
        bool active;
        uint voteStartBlock;
        bool startVote;
    }

    struct parliamentApply {
        address account;
        uint tickets;
        uint opposeTickets;
    }

    struct parliamentsVoteRecord{
        address[]  parliaments;
        mapping(address => bool) parliamentsVoted;
    }

    address public impeach;
    mapping(uint => tokenProposal) public tokenProposals;

    mapping(uint =>mapping(uint => parliamentsVoteRecord) ) private  parliamentsVote;
    EnumerableSet.AddressSet private parliament;
    Governance public override cgInfo;
    PublicStructs.InitGovernance public configure;
    mapping(uint => parliamentApply[]) public parliamentApplyRecords;
    mapping(uint => bool) public campaignState;

    mapping(uint =>mapping(address => bool)) public parliamentUp;

    event tokenProposalCreate(uint indexed id,address owner,uint creationTime);


    enum CampaignState {
        normal,
        signUp, //
        vote,
        publicity
    }

    constructor(address gov_token,PublicStructs.InitGovernance memory inGov)  {
        cgInfo.govToken = gov_token;
        cgInfo.votePeriod = true;  //open vote after new this contract
        cgInfo.proposalBlockNumber = block.number;
        configure = inGov;
        Impeach  ip = new Impeach();
        impeach = address(ip);
        IERC20(gov_token).approve(impeach,type(uint256).max);
        IToken(gov_token).initDaoAddr(address(this));
    }

    function activeToParliaments() public {
        require(cgInfo.expireBlock < block.number);
        require(cgInfo.votePeriod == false);
        _startVoteParliament();
    }

    function _startVoteParliament() internal{
        uint parliamentLength = parliament.length();
        for (uint i = 0; i < parliamentLength; i++) {
            address user = parliament.at(i);
            parliament.remove(user);
        }
        if(cgInfo.firstActive == false) {
            cgInfo.firstActive = true;
        }
        cgInfo.proposalBlockNumber = block.number;
        cgInfo.votePeriod = true;
        cgInfo.voteId += 1;
    }


    function getBlockNumber() external override view returns(uint) {
         return  cgInfo.proposalBlockNumber;
    }


    function _setParliament(uint voteId, uint index) internal   {
        address user = parliamentApplyRecords[voteId][index].account;
//        parliament.add(user);
        parliamentUp[voteId][user] = true;
        cgInfo.impeachIndex++;
    }
    function setParliament(uint voteId) external override   {
        require(msg.sender == impeach,'no access');
        address user = parliamentApplyRecords[voteId][cgInfo.impeachIndex].account;
        parliamentUp[voteId][user] = true;
        cgInfo.impeachIndex++;
    }
    function getParliamentLength() public view returns(uint)  {
        return parliament.length();
    }
    function getParliamentByIndex(uint index) public view returns(address) {
        return parliament.at(index);
    }


    function parliamentTakeOffice() public {
        require(parliamentUp[cgInfo.voteId][msg.sender],'no access');
        require( IERC20(cgInfo.govToken).balanceOf(msg.sender) >= configure.depositCount * 10 ** 18,'not enough rbt');
        TransferHelper.safeTransferFrom(cgInfo.govToken,msg.sender,address(this),configure.depositCount * 10 ** 18);
        parliament.add(msg.sender);
    }


    function getCampaignState() public view returns(CampaignState) {
        if(cgInfo.votePeriod == false) {
            return CampaignState.normal;
        }else if(cgInfo.votePeriod == true){
            return CampaignState.signUp;
        }else if(cgInfo.startVote == true) {
            return CampaignState.vote;
        } else {
            return CampaignState.publicity;
        }
    }
    function getApplyUserLength(uint voteId)  public view returns(uint){
        return parliamentApplyRecords[voteId].length;
    }

    function applyParliament() external   {
        require(IERC20(cgInfo.govToken).balanceOf(msg.sender) >= configure.depositCount * 10 ** 18 ,'not enough gov token');
        require(cgInfo.votePeriod == true,'not in apply time');
        TransferHelper.safeTransferFrom(cgInfo.govToken,msg.sender,address(this),configure.depositCount * 10 ** 18);
        uint length = parliamentApplyRecords[cgInfo.voteId].length;
        if (cgInfo.firstActive == true) {
            if (length > configure.applyMemberCount) {
                require(cgInfo.expireBlock < block.number && cgInfo.expireBlock + configure.applyTime > block.number, 'not in time');
            } else {
                require(cgInfo.expireBlock < block.number, 'not in time');
            }
        }
        _setParliamentApply(cgInfo.voteId,msg.sender,0,0);
    }

    function _setParliamentApply( uint voteId,address sender,uint tickets,uint opposeTickets) internal  {
        parliamentApply memory ar = parliamentApply({
            account : sender,
            tickets : tickets,
            opposeTickets:opposeTickets
        });
        parliamentApplyRecords[voteId].push(ar);
    }


    function startVote () public {
        require(cgInfo.startVote == false);
        cgInfo.startVote = true;
        cgInfo.voteStartBlock = block.number;
    }

    function voteToParliament(address user, uint tickets) external override   {
        require(cgInfo.startVote = true);
        uint length = parliamentApplyRecords[cgInfo.voteId].length;
        require(length >= configure.applyMemberCount && cgInfo.expireBlock < block.number,'not in vote time');
        require(IToken(cgInfo.govToken).delegateVotes(msg.sender,cgInfo.proposalBlockNumber) >= tickets,'delegate not enough');
        IToken(cgInfo.govToken).useDelegateVote(msg.sender,tickets);
        bool existsUser = false;
        for (uint i = 0; i < length; i++) {
            if (user == parliamentApplyRecords[cgInfo.voteId][i].account) {
                existsUser = true;
                parliamentApplyRecords[cgInfo.voteId][i].tickets += (tickets);
                break;
            }
        }
        require(existsUser == true);
    }


    function opposeToParliament(address user, uint tickets) external    {
        require(block.number >= (cgInfo.voteStartBlock + configure.voteInterval));
        uint length = parliamentApplyRecords[cgInfo.voteId].length;
        require(IToken(cgInfo.govToken).delegateVotes(msg.sender,cgInfo.proposalBlockNumber) >= tickets,'delegate not enough');
        IToken(cgInfo.govToken).useDelegateVote(msg.sender,tickets);
        bool existsUser = false;
        for (uint i = 0; i < length; i++) {
            if (user == parliamentApplyRecords[cgInfo.voteId][i].account) {
                existsUser = true;
                parliamentApplyRecords[cgInfo.voteId][i].opposeTickets += (tickets);
                uint allVote =  IToken(cgInfo.govToken).allDelegateVotes(cgInfo.proposalBlockNumber);
                if(parliamentApplyRecords[cgInfo.voteId][i].opposeTickets > allVote.mul(20).div(100)) {
                    parliament.remove(user);
                    _setParliament(cgInfo.voteId,cgInfo.impeachIndex);
                }
                break;
            }
        }
        require(existsUser == true);
    }

    function endToParliament() external   {
        uint length = parliamentApplyRecords[cgInfo.voteId].length;
        require(length >= configure.applyMemberCount ,'not enough people');
        require(cgInfo.votePeriod == true);
        require(campaignState[cgInfo.voteId] == false);
        _quickSort(parliamentApplyRecords[cgInfo.voteId], 0, length);
        cgInfo.votePeriod = false;
        cgInfo.expireBlock = block.number + configure.workDays;
        for (uint i = 0; i <= configure.parliamentCount - 1; i++) {
            parliament.add(parliamentApplyRecords[cgInfo.voteId][i].account);
        }
        if (length > configure.parliamentCount) {
            for (uint i = configure.parliamentCount; i < length; i++) {
                address user = parliamentApplyRecords[cgInfo.voteId][i].account;
                TransferHelper.safeTransferFrom(cgInfo.govToken,address(this),user,configure.depositCount * 10 ** 18);
            }
        }
        campaignState[cgInfo.voteId] = true;
    }


     function takeOffice() public {
        require(block.number >= (cgInfo.voteStartBlock + configure.voteInterval + configure.publicityTime));
        require(campaignState[cgInfo.voteId] = true);
        cgInfo.active = true;
     }

    function comGovApplyToken(uint stage,uint day ,uint applyAmount,string memory description) public {
        tokenProposalCount++;
        require(IERC20(cgInfo.govToken).balanceOf(msg.sender) >= 1000 * 10 ** 18 ,'not enough gov token');
        TransferHelper.safeTransferFrom(cgInfo.govToken,msg.sender,address(this),500 * 10 ** 18 );
        tokenProposal storage c = tokenProposals[tokenProposalCount];
        c.id = tokenProposalCount;
        c.owner = msg.sender;
        c.stage = stage;
        c.day = day;
        c.applyAmount = applyAmount;
        c.depositAmount = 500 * 10 ** 18;
        c.description = description;
        c.parliamentsAgree = 0 ;
        c.creationTime = block.timestamp;
        emit tokenProposalCreate(c.id,msg.sender,block.timestamp);
    }
    function getCurrentStage(uint id) public view returns(uint) {
        uint stage = tokenProposals[id].stage;
        while (stage > 0) {
            if(tokenProposals[id].everyStageDetails[stage].oppose < configure.approveCount &&
                block.timestamp > tokenProposals[id].everyStageDetails[stage].startTime + 3 days) {
                return stage;
            }
            stage--;
        }
        return 0;
    }

    function parliamentsVoteProposal(uint id,uint stage) external   {
        require(parliament.contains(msg.sender),'no access');
        require(stage>=0 && stage<=tokenProposals[id].stage,'not in stage');
        require(parliamentsVote[id][stage].parliamentsVoted[msg.sender] == false,'voted');
        parliamentsVote[id][stage].parliamentsVoted[msg.sender] = true;
        parliamentsVote[id][stage].parliaments.push(msg.sender);
        if(stage == 0) {
            require(block.timestamp < tokenProposals[id].creationTime + 3 days ,'not in time');
            tokenProposals[id].parliamentsAgree++;
            if(tokenProposals[id].parliamentsAgree == configure.approveCount) {
                tokenProposals[id].voteStartTime == block.timestamp;
                tokenProposals[id].everyStageDetails[1].startTime = block.timestamp + 7 days;
            }
            require(tokenProposals[id].parliamentsAgree <= configure.approveCount ,'this proposal is adopt');
        } else {
            uint allticket =  IToken(cgInfo.govToken).allDelegateVotes(cgInfo.proposalBlockNumber);
            if(stage == 1) {
                require(tokenProposals[id].parliamentsAgree == configure.approveCount && tokenProposals[id].opposeTickets < allticket.mul(30).div(100),'prev stage is not finished');
            }else{
                require(tokenProposals[id].everyStageDetails[stage-1].oppose < configure.approveCount &&
                block.timestamp > tokenProposals[id].everyStageDetails[stage-1].startTime + 3 days,'');
            }
            tokenProposals[id].everyStageDetails[stage].oppose++;
            if(tokenProposals[id].everyStageDetails[stage].oppose == configure.approveCount) {

                require(tokenProposals[id].everyStageDetails[stage].againSecond <= 3 ,' no chance');
                tokenProposals[id].everyStageDetails[stage].oppose = 0;
                tokenProposals[id].everyStageDetails[stage].againSecond++;
                tokenProposals[id].everyStageDetails[stage].canSubmit = true;

                uint voteLength = parliamentsVote[id][stage].parliaments.length;
                for(uint i = 0; i< voteLength;i++){
                    delete parliamentsVote[id][stage].parliamentsVoted[parliamentsVote[id][stage].parliaments[i]];
                }
                delete parliamentsVote[id][stage].parliaments;
            }
        }
    }

    function voteToProposal(uint id,uint tickets) public  {
        require(tokenProposals[id].voteStartTime + 7 days > block.timestamp && tokenProposals[id].parliamentsAgree == configure.approveCount);
        require(IToken(cgInfo.govToken).delegateVotes(msg.sender,cgInfo.proposalBlockNumber) >= tickets,'delegate not enough');
        IToken(cgInfo.govToken).useDelegateVote(msg.sender,tickets);
        tokenProposals[id].opposeTickets = tokenProposals[id].opposeTickets.add(tickets);
    }


    function receiveToken(uint id,uint stage) external  {
        require(stage>0 && stage<=tokenProposals[id].stage,'not in stage');
        require(tokenProposals[id].owner == msg.sender);
        require(tokenProposals[id].everyStageDetails[stage].received == false,'no access to receive');
        if(stage == 1) {
            uint allticket =  IToken(cgInfo.govToken).allDelegateVotes(cgInfo.proposalBlockNumber);
            require(block.timestamp < tokenProposals[id].creationTime + 3 days ,'not in time');
            require(tokenProposals[id].parliamentsAgree == configure.approveCount);
            require(tokenProposals[id].opposeTickets < allticket.mul(30).div(100));
        }else {
            require(tokenProposals[id].everyStageDetails[stage -1].oppose < configure.approveCount && tokenProposals[id].everyStageDetails[stage - 1].startTime + tokenProposals[id].day < block.timestamp);
        }

        tokenProposals[id].everyStageDetails[stage].received = true;
        tokenProposals[id].everyStageDetails[stage].canSubmit = true;
        if(tokenProposals[id].stage >= stage + 1) {
            tokenProposals[id].everyStageDetails[stage+1].startTime = block.timestamp;
        }
        uint amount = tokenProposals[id].applyAmount.div(tokenProposals[id].stage);
        _extract(msg.sender,amount);

    }


    function submitReport(uint id,uint stage,string memory description) public {
        require(stage > 0 && stage <= tokenProposals[id].stage);
        require(tokenProposals[id].everyStageDetails[stage].canSubmit == true , 'Cannot submit at this time');
        tokenProposals[id].everyStageDetails[stage].description = description;
        tokenProposals[id].everyStageDetails[stage].canSubmit = false;
    }

    function getApplyParliamentVoteId() external  view override   returns (uint){
        return cgInfo.voteId;
    }


    function hasParliament(address user) external override  view returns (bool) {
        return  parliament.contains(user);
    }

    function _extract(address receiver,uint amount) internal {
        IERC20(cgInfo.govToken).transfer(receiver,amount);
    }

    function _quickSort(parliamentApply[] storage arr, uint left, uint right) internal {
        uint i = left;
        uint j = right;
        if (i == j) return;
        uint pivot = arr[uint(left + (right - left) / 2)].tickets;
        while (i <= j) {
            while (arr[uint(i)].tickets < pivot) i++;
            while (pivot < arr[uint(j)].tickets) j--;
            if (i <= j) {
                (arr[uint(i)], arr[uint(j)]) = (arr[uint(j)], arr[uint(i)]);
                i++;
                j--;
            }
        }
        if (left < j)
            _quickSort(arr, left, j);
        if (i < right)
            _quickSort(arr, i, right);
    }

}


