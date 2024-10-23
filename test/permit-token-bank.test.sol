// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { PermitTokenBank } from "../src/permit/permit-token-bank.sol";
import { PermitToken } from "../src/permit/permit-token.sol";

contract PermitTokenBankTest is Test {
  PermitTokenBank public bank;
  PermitToken public token;

  function setUp() public {
    token = new PermitToken("PermitToken", "PT");
    bank = new PermitTokenBank(token);
  }

  function testPermitDeposist(string calldata ownertName, uint256 amount) public {
    Vm.Wallet memory ownerWallet = vm.createWallet(ownertName);
    address ownerAddr = ownerWallet.addr;
    vm.assume(amount > 0);
    deal(address(token), ownerWallet.addr, amount);
    assertEq(token.balanceOf(address(bank)), 0);
    assertEq(token.balanceOf(ownerAddr), amount);
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = token.buildPermitArgsHashTypedDataV4(ownerAddr, address(bank), amount, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerWallet, digest);
    vm.prank(ownerAddr);
    bank.permitDeposit(amount, deadline, v, r, s);
    assertEq(token.balanceOf(address(bank)), amount);
    assertEq(token.balanceOf(ownerAddr), 0);
  }
}
