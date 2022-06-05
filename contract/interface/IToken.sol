pragma solidity ^0.8.0;

interface IToken {
    function delegateVotes( address sender, uint blockNumber) external view returns(uint);
    function allDelegateVotes(uint blockNumber) external view returns(uint);
    function useDelegateVote(address sender,uint amount)  external;
    function initDaoAddr(address addr) external;
}
