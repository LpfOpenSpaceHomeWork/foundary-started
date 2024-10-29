// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PermitToken } from "./permit-token.sol";
import { ISignatureTransfer, IPermit2 } from "../../lib/permit2/src/interfaces/IPermit2.sol";

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
    address depositor,
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    token.permit(depositor, address(this), amount, deadline, v, r, s);
    _deposit(depositor, amount);
  }

  struct PermitDetail {
    address owner;
    uint256 amount;
    uint256 deadline;
    uint256 nonce;
  }

  function permit2Deposit(PermitDetail calldata permitDetail, bytes calldata signature) public {
    ISignatureTransfer permit2 = IPermit2(0x77eB49386ff9ef934FE6f051b80B3e86f1EF6322);
    ISignatureTransfer.TokenPermissions memory permitted = ISignatureTransfer.TokenPermissions({
      token: address(token),
      amount: permitDetail.amount
    });
    ISignatureTransfer.PermitTransferFrom memory permit = ISignatureTransfer.PermitTransferFrom({
      permitted: permitted,
      nonce: permitDetail.nonce,
      deadline: permitDetail.deadline
    });
    ISignatureTransfer.SignatureTransferDetails memory transferDetails = ISignatureTransfer.SignatureTransferDetails({
      to: address(this),
      requestedAmount: permitDetail.amount
    });
    permit2.permitTransferFrom(permit, transferDetails, permitDetail.owner, signature);
  }
}
