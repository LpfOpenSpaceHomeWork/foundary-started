// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { Bank } from "../src/chainlink-automation/bank.sol";


contract DeployChainlinkAutomation is Script {
  function run() external {
    vm.startBroadcast();
    address ca = address(new Bank());
    console.log("Deployed to", ca);
    vm.stopBroadcast();
  }
}
