// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { AutomationCompatibleInterface } from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract Bank is AutomationCompatibleInterface, Ownable {
  mapping(address => uint256) public balanceOf;
  uint256 public upperLimitBalance;
  address public forwarder;

  constructor() Ownable(msg.sender) {
    upperLimitBalance = 0.001 ether;
    forwarder = payable(msg.sender);
  }

  modifier onlyForwarder {
    require(msg.sender == forwarder, "only forwarder can call the function");
    _;
  }

  event Deposit(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);

  function setUpperLimitBalance(uint256 newUpperLimitBalance) public onlyOwner {
    upperLimitBalance = newUpperLimitBalance;
  }

  function setForwarder(address payable addr) public onlyOwner {
    forwarder = addr;
  }

  function deposit() public payable {
    require(msg.value > 0, "deposit amount must be greater than 0");
    balanceOf[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
  }

  function withdraw(address payable to, uint256 amount) private {
    (bool success,) = to.call{value: amount}("");
    require(success, "tx error");
    emit Withdraw(to, amount);
  }

  function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory data) {
    upkeepNeeded = (address(this).balance > upperLimitBalance);
    data = "";
  }

  function performUpkeep(bytes calldata) external override onlyForwarder {
    if (address(this).balance > upperLimitBalance) {
      withdraw(payable(owner()), address(this).balance / 2);
    }
  }
}
