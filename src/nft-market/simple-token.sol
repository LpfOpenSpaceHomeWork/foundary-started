// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { console } from "forge-std/console.sol";

library Address {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

error FailedToCallTokenReceivedHook();

interface ISimpleTokenReceiver {
  function tokensReceived(address from,uint256 amount,bytes calldata data) external;
}

contract SimpleToken is ERC20, Ownable {
  using Address for address;
  constructor(string memory _name, string memory _symbol)
    ERC20(_name, _symbol)
    Ownable(msg.sender)
  {}

  function decimals() public pure virtual override returns(uint8)  {
    return 2;
  }

  function mint(address to, uint256 amount) public {
    console.log(msg.sender);
    _mint(to, amount);
  }

  function transferWithCallback(ISimpleTokenReceiver to, uint256 amount, bytes calldata data) external returns (bool) {
    address from = msg.sender;
    _transfer(from, address(to), amount);
    if (address(to).isContract()) {
      ISimpleTokenReceiver(to).tokensReceived(from, amount, data);
    }
    return true;
  }
}
