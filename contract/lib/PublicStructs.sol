pragma solidity ^0.8.0;


library PublicStructs {
  struct InitGovernance {
    uint parliamentCount; //13
    uint approveCount;//7
    uint workDays; //599940  (90 days)
    uint applyTime; // 93324  (14 days)
    uint applyMemberCount; // 30
    uint depositCount; // 5000 gov token
    uint voteInterval;// 46662
    uint publicityTime; //19998
    string name;
  }
  struct Impeach {
    uint id;
    uint tickets;
    address acceptor; // 被弹的人
    address sponsor; //发起人
    uint creationBlock;
    bool success;
  }
}
