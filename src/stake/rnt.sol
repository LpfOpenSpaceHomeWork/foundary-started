// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract RNT is ERC20 , ERC20Permit, Ownable{
  constructor() ERC20("Reward Token", "RNT")ERC20Permit("Reward Token")Ownable(msg.sender){
    _mint(msg.sender, 1000000 * 10 ** decimals());
  }
}
