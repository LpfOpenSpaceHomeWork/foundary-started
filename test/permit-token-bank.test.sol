// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { PermitTokenBank } from "../src/permit/permit-token-bank.sol";
import { PermitToken } from "../src/permit/permit-token.sol";

contract PermitTokenBankTest is Test {
  PermitTokenBank public bank;
  PermitToken public token;

  function setUp() public {
    token = new PermitToken("PermitToken", "PT");
    bank = new PermitTokenBank(token);
  }

  function _getDepositorWallet(string calldata depositorName, uint256 amount) private returns(Vm.Wallet memory) {
    Vm.Wallet memory depositorWallet = vm.createWallet(depositorName);
    vm.assume(amount > 0);
    deal(address(token), depositorWallet.addr, amount);
    assertEq(token.balanceOf(address(bank)), 0);
    assertEq(token.balanceOf(depositorWallet.addr), amount);
    return depositorWallet;
  }

  function testPermitDeposit(string calldata depositorName, uint256 amount) public {
    Vm.Wallet memory depositorWallet = _getDepositorWallet(depositorName, amount);
    address depositorAddr = depositorWallet.addr;
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = token.buildPermitArgsHashTypedDataV4(depositorAddr, address(bank), amount, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(depositorWallet, digest);
    bank.permitDeposit(depositorAddr, amount, deadline, v, r, s);
    assertEq(token.balanceOf(address(bank)), amount);
    assertEq(token.balanceOf(depositorAddr), 0);
  }

  function testRevertPermitDepositExpiredSignature(string calldata depositorName, uint256 amount) public {
    Vm.Wallet memory depositorWallet = _getDepositorWallet(depositorName, amount);
    address depositorAddr = depositorWallet.addr;
    uint256 expiredDeadline = 1 days;
    vm.warp(2 days);
    bytes32 digest = token.buildPermitArgsHashTypedDataV4(depositorAddr, address(bank), amount, expiredDeadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(depositorWallet, digest);
    vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612ExpiredSignature.selector, expiredDeadline));
    bank.permitDeposit(depositorAddr, amount, expiredDeadline, v, r, s);
    assertEq(token.balanceOf(address(bank)), 0);
    assertEq(token.balanceOf(depositorAddr), amount);
  }

  function testRevertPermitDepositInvalidSignature(string calldata depositorName, string calldata signerName, uint256 amount) public {
    Vm.Wallet memory depositorWallet = _getDepositorWallet(depositorName, amount);
    Vm.Wallet memory signnerWallet = vm.createWallet(signerName);
    address depositorAddr = depositorWallet.addr;
    address signerAddr = signnerWallet.addr;
    vm.assume(depositorAddr != signerAddr);
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = token.buildPermitArgsHashTypedDataV4(depositorAddr, address(bank), amount, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(signnerWallet, digest);
    vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, signerAddr, depositorAddr));
    bank.permitDeposit(depositorAddr, amount, deadline, v, r, s);
    assertEq(token.balanceOf(address(bank)), 0);
    assertEq(token.balanceOf(depositorAddr), amount);
  }

  function testRevertPermitDepositUseSignatureMultipleTimes(string calldata depositorName, uint256 amount) public {
    Vm.Wallet memory depositorWallet = _getDepositorWallet(depositorName, amount);
    address depositorAddr = depositorWallet.addr;
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = token.buildPermitArgsHashTypedDataV4(depositorAddr, address(bank), amount, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(depositorWallet, digest);
    bank.permitDeposit(depositorAddr, amount, deadline, v, r, s);
    assertEq(token.balanceOf(address(bank)), amount);
    assertEq(token.balanceOf(depositorAddr), 0);
    // 此时nonce已经变了，算出来的verifyingDigest和digest是不一样的
    bytes32 verifyingDigest = token.buildPermitArgsHashTypedDataV4(depositorAddr, address(bank), amount, deadline);
    address invalidSigner = ECDSA.recover(verifyingDigest, v, r, s);
    vm.expectRevert(abi.encodeWithSelector(ERC20Permit.ERC2612InvalidSigner.selector, invalidSigner, depositorAddr));
    bank.permitDeposit(depositorAddr, amount, deadline, v, r, s);
    assertEq(token.balanceOf(address(bank)), amount);
    assertEq(token.balanceOf(depositorAddr), 0);
  }
}
