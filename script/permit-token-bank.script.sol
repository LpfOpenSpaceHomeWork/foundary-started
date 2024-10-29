// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Script } from "forge-std/Script.sol";
import { PermitToken } from "../src/permit/permit-token.sol";
import { PermitTokenBank } from "../src/permit/permit-token-bank.sol";
import { console } from "forge-std/console.sol";

bytes32 constant PERMIT_TOKEN_SALT = bytes32(uint256(0x01));
bytes32 constant PERMIT_TOKEN_BANK_SALT = bytes32(uint256(0x02));

contract DeployPermitTokenBank is Script {
    function run() external {
        vm.startBroadcast();
        PermitToken permitToken = new PermitToken{ salt: PERMIT_TOKEN_SALT }("Permit Token", "PT");
        console.log("PermitToken deployed at", address(permitToken));
        PermitTokenBank permitTokenBank = new PermitTokenBank{ salt: PERMIT_TOKEN_BANK_SALT }(permitToken);
        console.log("PermitTokenBank deployed at", address(permitTokenBank));
        vm.stopBroadcast();
    }
}
