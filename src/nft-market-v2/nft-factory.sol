// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC721NFT } from "./erc-721-nft.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract NFTFactory {
  event ERC721NFTCreated(address indexed nftAddr, string indexed name, string indexed symbol);

  address public immutable nftImplementation;

  constructor() {
    nftImplementation = address(new ERC721NFT());
  }

  function createERC721NFT(string calldata name, string calldata symbol) public returns (address) {
    address nftAddr = Clones.clone(nftImplementation);
    ERC721NFT(nftAddr).init(name, symbol);
    emit ERC721NFTCreated(nftAddr, name, symbol);
    return nftAddr;
  }
}
