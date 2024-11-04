// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenPreSale {
  IERC20 public token; // 预售的Token CA
  address public owner; // 合约所有者
  uint256 public price; // 预售价格(wei)
  uint256 public supply; // 预售数量
  uint256 public maxAmountPerAccount; // 每个账号允许购买的token数量上限
  uint256 public startTime; // 预售开始时间
  uint256 public endTime; // 预售结束时间
  bool public isInitialized; // 预售是否初始化

  mapping(address => uint256) public contributions; // 用户贡献的ETH数量(wei)

  event Contribution(address indexed user, uint256 contribution, uint256 tokenAmount);
  event ClaimTokens(address indexed user, uint256 amount);
  event RefundETHs(address indexed user, uint256 amount);
  event ClaimETHs(address indexed user, uint256 amount);
  event RefundTokens(address indexed user, uint256 amount);

  struct PreSaleInfo {
    address tokenCA; // 预售的Token CA
    uint256 price; // 预售价格(wei)
    uint256 supply; // 预售数量
    uint256 maxAmountPerAccount; // 每个账号允许购买的token数量上限
    uint256 startTime; // 预售开始时间
    uint256 duration; // 持续时间
  }

  function init(PreSaleInfo memory _preSaleInfo) public {
    require(!isInitialized, "Already initialized");
    require(token.balanceOf(address(this)) >= _preSaleInfo.supply, "Insufficient token balance");
    token = IERC20(_preSaleInfo.tokenCA);
    owner = msg.sender;
    price = _preSaleInfo.price;
    supply = _preSaleInfo.supply;
    maxAmountPerAccount = _preSaleInfo.maxAmountPerAccount;
    startTime = block.timestamp;
    endTime = startTime + _preSaleInfo.duration;
    isInitialized = true;
  }

  modifier onlyInitialized() {
    require(isInitialized, "Not initialized");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
  }

  modifier onlyWhileActive() {
    require(block.timestamp >= startTime && block.timestamp <= endTime, "PreSale not within duration");
    uint256 target = supply * price;
    require(address(this).balance < target, "Tokens sold out");
    _;
  }

  modifier onlyAfterSucceed() {
    uint256 target = supply * price;
    require(address(this).balance >= target, "PreSale not successful");
    _;
  }

  modifier onlyAfterFailure() {
    uint256 target = supply * price;
    require(block.timestamp > endTime, "PreSale is not over");
    require(address(this).balance < target, "PreSale has been successful");
    _;
  }

  // 用户参与预售
  function participate() public payable onlyInitialized onlyWhileActive {
    uint256 contribution = contributions[msg.sender] + msg.value;
    uint256 tokenAmountToPurchase = contribution / price;
    require(tokenAmountToPurchase <= maxAmountPerAccount, "Exceeds max amount per account");
    contributions[msg.sender] = contribution;
    emit Contribution(msg.sender, contribution, tokenAmountToPurchase);
  }

  // 用户兑付token
  function claimTokens() public onlyAfterSucceed {
    uint256 tokenAmount = contributions[msg.sender] / price;
    require(tokenAmount > 0, "No tokens to claim");
    contributions[msg.sender] = 0;
    token.transferFrom(address(this), msg.sender, tokenAmount);
    emit ClaimTokens(msg.sender, tokenAmount);
  }

  // 用户赎回ETH
  function refundETHs() public onlyAfterFailure {
    uint256 contribution = contributions[msg.sender];
    require(contribution > 0, "No contribution to refund");
    (bool success,) = payable(msg.sender).call{value: contribution}("");
    require(success, "Failed to refund");
    contributions[msg.sender] = 0;
    emit RefundETHs(msg.sender, contribution);
  }

  // token售卖者提现
  function claimETHs() public onlyOwner onlyAfterSucceed {
    (bool success,) = payable(owner).call{value: address(this).balance}("");
    require(success, "Failed to withdraw");
    emit ClaimETHs(owner, address(this).balance);
  }

  // token售卖者赎回tokens
  function refundTokens() public onlyOwner onlyAfterFailure() {
    token.transfer(owner, token.balanceOf(address(this)));
    emit RefundTokens(owner, token.balanceOf(address(this)));
  }

  receive() external payable {
    participate();
  }

  fallback() external payable {
    participate();
  }
}
