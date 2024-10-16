// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    event Deposit(address indexed user, uint amount);

    function setUp() public {
        bank = new Bank();
    }

    function testDepositETH(uint96 amount) public {
      vm.expectEmit(true, true, false, false);
      vm.assume(amount > 0);
      emit Deposit(address(this), amount);
      bank.depositETH{value: amount}();
      assertEq(bank.balanceOf(address(this)), amount);
    }
}
