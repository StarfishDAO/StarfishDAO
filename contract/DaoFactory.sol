pragma solidity ^0.8.0;
import './GovernanceDao.sol';

import {PublicStructs} from './lib/PublicStructs.sol';

contract DaoFactory {
       using EnumerableSet for EnumerableSet.AddressSet;

    struct userData {
        EnumerableSet.AddressSet daos;
    }
    struct daoInfo {
        string name;
        address dao;
    }
    mapping(address => userData) private _userDaos;
    daoInfo[] public daos;

    function createDao(uint parliamentCount, uint approveCount, uint workDays, uint applyTime, uint applyMemberCount, uint depositCount, uint voteInterval, uint publicityTime, string memory name,address govToken
    ) public returns(address){
        PublicStructs.InitGovernance memory pi = PublicStructs.InitGovernance({
            parliamentCount:parliamentCount,
            approveCount:approveCount,
            workDays:workDays,
            applyTime:applyTime,
            applyMemberCount:applyMemberCount,
            depositCount:depositCount,
            voteInterval:voteInterval,
            publicityTime:publicityTime,
            name:name
        });
        GovernanceDao dao = new GovernanceDao(govToken,pi);
        daoInfo memory df = daoInfo({name:name,dao:address(dao)});
        daos.push(df);
        _userDaos[msg.sender].daos.add(address(dao));
        return (address(dao));
    }
    function getDaoCount() public view returns(uint) {
        return daos.length;
    }
    function joinDao(address daoAddress) public {
        require(hasDao(msg.sender,daoAddress) == false,'error:you already join this dao');
        _userDaos[msg.sender].daos.add(daoAddress);
    }
    function hasDao(address user,address dao) public  view returns (bool){
        return _userDaos[user].daos.contains(dao);
    }

    function getUserDaoLength(address user) public view returns(uint)  {
        return _userDaos[user].daos.length();
    }
    function getUserDaoByIndex(address user , uint index) public view returns(address) {
        return _userDaos[user].daos.at(index);
    }
}




