pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "./lib/TransferHelper.sol";
import {PublicStructs} from './lib/PublicStructs.sol';
import './interface/IGovernanceDao.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interface/IToken.sol';
contract Impeach  {
    using SafeMath for uint256;
    uint public  impeachCount;
    address public gov;

    mapping(uint => PublicStructs.Impeach) public impeachs;

    event impeachCreate(uint indexed id,address sponsor,address acceptor);

     constructor() public  {
         gov = msg.sender;
     }

    function impeachCommunityGovFund(address user) external  {
        (,,,,, address govToken,,,,)= IGovernanceDao(gov).cgInfo();
        impeachCount++;
        require(IGovernanceDao(gov).hasParliament(user), 'no this user');
        require(IERC20(govToken).balanceOf(msg.sender) >= 1000 * 10 ** 18 ,'not enough gov token');
        TransferHelper.safeTransferFrom(govToken,msg.sender,gov,1000 * 10 ** 18);
        PublicStructs.Impeach storage c = impeachs[impeachCount];
        c.id = impeachCount;
        c.acceptor = user;
        c.sponsor = msg.sender;
        c.tickets = 0;
        c.success = false;
        c.creationBlock = block.number;
        emit impeachCreate(c.id,msg.sender,user);
    }
    function voteToImpeach(uint id,uint tickets) public {
        require(impeachs[id].success == false,'is finished');
        require(block.number < impeachs[id].creationBlock + 46662);
       (,uint voteId,,,uint proposalBlockNumber, address govToken,,,,)= IGovernanceDao(gov).cgInfo();
        require(IToken(govToken).delegateVotes(msg.sender,proposalBlockNumber) >= tickets,'delegate not enough');
        IToken(govToken).useDelegateVote(msg.sender,tickets);
        uint allVote =  IToken(govToken).allDelegateVotes(proposalBlockNumber);
        impeachs[id].tickets = impeachs[id].tickets.add(tickets);
        if( impeachs[id].tickets  > allVote.mul(20).div(100)) {
            impeachs[id].success = true;
            TransferHelper.safeTransferFrom(govToken,gov,impeachs[id].sponsor,5000 * 10 ** 18);
            IGovernanceDao(gov).setParliament(voteId);
        }
    }

}


