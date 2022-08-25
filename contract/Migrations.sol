// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//kovan 0xCdd27850AC3f1D999166E11408DEA1137b28C5b7
//ropsten 0xb53E020F21bC17479443d7552F5681538d9De61c

contract Migrations {
  address public owner = msg.sender;
  uint public last_completed_migration;

  modifier restricted() {
    require(
      msg.sender == owner,
      "This function is restricted to the contract's owner"
    );
    _;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }
}

