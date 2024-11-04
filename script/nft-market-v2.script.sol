// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { NFTMarketV2 } from "../src/nft-market-v2/nft-market.sol";
import { NFTFactory } from "../src/nft-market-v2/nft-factory.sol";
import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";

bytes32 constant NFT_MARKET_V2_SALT = bytes32(uint256(0x03));
bytes32 constant NFT_FACTORY_SALT = bytes32(uint256(0x04));

contract DeployNFTMarketV2 is Script {
  function run() public {
    vm.startBroadcast();
    NFTMarketV2 nftMarketV2 = new NFTMarketV2{ salt: NFT_MARKET_V2_SALT }();
    NFTFactory nftFactory = new NFTFactory{ salt: NFT_FACTORY_SALT }();
    console.log("NFTMarketV2 deployed at", address(nftMarketV2));
    console.log("NFTFactory deployed at", address(nftFactory));
    vm.stopBroadcast();
  }
}
