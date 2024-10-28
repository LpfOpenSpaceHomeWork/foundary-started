// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Script } from "forge-std/Script.sol";
import { MultiSigWallet } from "../src/multi-sig-wallet/multi-sig-wallet.sol";

contract DeployMultiSigWallet is Script {
    function run() external {
        vm.startBroadcast();
        address[] memory signers = new address[](3);
        signers[0] = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        signers[1] = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
        signers[2] = 0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC;
        new MultiSigWallet(signers, 2);
        vm.stopBroadcast();
    }
}
