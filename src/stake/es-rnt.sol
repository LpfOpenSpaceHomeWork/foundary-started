// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { RNT } from "./rnt.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract esRNT is ERC20, Ownable {
  struct LockInfo {
    address user;
    uint256 amount; // 锁仓数量
    uint256 lockTime; // 锁仓时间
  }

  LockInfo[] public locks;
  RNT public rntToken;

  event Minted(address indexed _user, uint256 _amount, uint256 lockId);

  constructor(RNT _rntToken) ERC20("Escrowed Reward Token", "esRNT") Ownable(msg.sender){
    rntToken = _rntToken;
    _transferOwnership(msg.sender);
  }

  function mint(address to, uint256 amount) public onlyOwner returns (uint256 lockId) {
    _mint(to, amount);
    locks.push(LockInfo({
      user: to,
      amount: amount,
      lockTime: block.timestamp
    }));
    lockId = locks.length - 1;
    emit Minted(to, amount, lockId);
  }

  function burn(uint256 lockId) public {
    require(lockId <  locks.length, "Invalid lockId");
    LockInfo storage lock = locks[lockId];
    require(lock.user == msg.sender, "Not the owner of the lock");
    // 达到30天的利率为100%，不足30天的直接burn掉
    uint256 profitRate = (block.timestamp - lock.lockTime) / 30 days;
    uint256 unlocked = lock.amount * profitRate;
    uint256 burnAmount= lock.amount - unlocked;
    _burn(msg.sender, lock.amount);
    rntToken.transfer(msg.sender, unlocked);
    rntToken.transfer(address(0), burnAmount);
  }
}
