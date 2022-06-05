pragma solidity ^0.8.0;

interface IGovernanceDao {
    function voteToParliament( address user, uint tickets) external;
    function cgInfo() external returns(uint expireTime,uint voteId,bool votePeriod,uint impeachIndex,uint proposalBlockNumber, address govToken,bool firstActive,bool active,uint voteStartBlock, bool startVote);
    function hasParliament(address user) external  view returns (bool);

//    function removeParliament(address user) external;
    function getApplyParliamentVoteId() external view returns (uint);
    function setParliament(uint voteId) external;
    function getBlockNumber() external  view returns(uint);

    // function impeachExtract(address token, uint amount, address receiver) external;

    // function applyTokenExtract(address receiver, uint[] memory portion, string[] memory where, address token) external;
}
