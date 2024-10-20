// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { MyERC20Token } from "../src/learn-to-deploy/my-erc20-token.sol";

contract DeployMyToken is Script {
    function run() external {
        vm.startBroadcast();
        new MyERC20Token("MyToken", "MTK");
        vm.stopBroadcast();
    }
}
