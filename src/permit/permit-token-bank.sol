// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PermitToken } from "./permit-token.sol";

contract TokenBank {

    PermitToken public token;
    mapping(address => uint) public deposits;

    constructor(PermitToken _token) {
        token = _token;
    }

    function _deposit(address caller, uint256 amount) internal {
      require(amount <= token.allowance(caller, address(this)), "No enough token approved to deposit");
      token.transferFrom(caller, address(this), amount);
      deposits[caller] += amount;
    }

    // ensure you have approve the bank to transfer your token;
    function deposit(uint256 amount) public {
      _deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) public {
        require(deposits[msg.sender] >= amount, "No enough token balance to withdraw");
        token.transfer(msg.sender, amount);
        deposits[msg.sender] -= amount;
    }
}

contract PermitTokenBank is TokenBank {
  constructor(PermitToken _token) TokenBank(_token) {

  }

  function permitDeposit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    token.permit(msg.sender, address(this), amount, deadline, v, r, s);
    _deposit(msg.sender, amount);
  }
}
