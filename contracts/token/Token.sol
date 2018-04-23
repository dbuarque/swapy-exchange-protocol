pragma solidity ^0.4.23;

import "zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";

contract Token is MintableToken {
    
    string public constant name = "SWAPY";
    string public constant symbol = "SWAPY";
    uint8 public constant decimals = 18;

} 