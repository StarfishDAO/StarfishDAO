pragma solidity ^0.8.0;
import './Token.sol';
contract ERC20Factory {
    function newToken(address manager,uint totalSupply,string memory name,string memory symbol) public returns(address) {
        Token govToken = new Token(manager,totalSupply,name,symbol);
        return address(govToken);
    }
}
