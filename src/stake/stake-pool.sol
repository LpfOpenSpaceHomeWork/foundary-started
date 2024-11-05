// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { RNT } from "./rnt.sol";
import { esRNT } from "./es-rnt.sol";

contract StakePool is Ownable {
  RNT public rntToken;
  esRNT public esrntToken;
  mapping(address => StakeInfo) public stakes;

  struct StakeInfo {
    uint256 staked;
    uint256 unclaimed;
    uint256 lastUpdateTime;
  }

  constructor(RNT _rntToken,esRNT _esrntToken) Ownable(msg.sender) {
    rntToken = _rntToken;
    esrntToken = _esrntToken;
  }

  function stake(uint256 amount) external {
    updateReward(msg.sender);
    require(amount > 0, "Amount must be greater than 0");
    rntToken.transferFrom(msg.sender, address(this), amount);
    stakes[msg.sender].staked += amount;
  }

  function unstake(uint256 amount) external {
    updateReward(msg.sender);
    require(amount > 0, "Amount must be greater than 0");
    require(stakes[msg.sender].staked >= amount, "Insufficient balance");
    stakes[msg.sender].staked -= amount;
    rntToken.transfer(msg.sender, amount);
  }

  function claim() external {
    updateReward(msg.sender);
    uint256 reward = stakes[msg.sender].unclaimed;
    stakes[msg.sender].unclaimed = 0;
    esrntToken.transfer(msg.sender, reward);
  }

  function updateReward(address account) internal {
    StakeInfo storage stakeInfo = stakes[account];
    if (stakeInfo.lastUpdateTime > 0) {
      uint256 stakedDays = (block.timestamp - stakeInfo.lastUpdateTime) / 1 days;
      uint256 profitRate = stakedDays * 1; // 日利率为100%
      stakeInfo.unclaimed += (profitRate * stakeInfo.staked);
    }
    stakeInfo.lastUpdateTime = block.timestamp;
  }
}
