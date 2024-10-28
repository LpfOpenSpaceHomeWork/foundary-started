// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { PermitToken } from "../src/permit/permit-token.sol";
import { PermitTokenBank } from "../src/permit/permit-token-bank.sol";

contract DeployPermitTokenBank is Script {
    function run() external {
        vm.startBroadcast();
        PermitToken permitToken = new PermitToken("Permit Token", "PT");
        new PermitTokenBank(permitToken);
        vm.stopBroadcast();
    }
}
