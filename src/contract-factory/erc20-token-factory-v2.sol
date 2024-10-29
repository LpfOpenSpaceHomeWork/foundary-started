// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { BaseERC20Token } from "./base-erc-20-token.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

contract ERC20TokenFactoryV2 {
  error NotReachedTokenPrice(uint256 price, uint256 paid);

  event InscriptionDeployed(string symbol, address tokenAddr);

  mapping(address => uint256) private tokenMintPriceMap;
  address private _baseERC20TokenAddr;

  constructor(address baseERC20TokenAddr) {
    _baseERC20TokenAddr = baseERC20TokenAddr;
  }

  function deployInscription(string calldata symbol, uint256 maxSupply, uint256 perMint, uint256 price) public returns(address) {
    address deployedTokenAddr = Clones.clone(_baseERC20TokenAddr);
    BaseERC20Token deployedToken = BaseERC20Token(deployedTokenAddr);
    deployedToken.init(symbol, maxSupply, perMint);
    tokenMintPriceMap[deployedTokenAddr] = price;
    emit InscriptionDeployed(symbol, deployedTokenAddr);
    return deployedTokenAddr;
  }

  function mintInscription(address tokenAddr) payable public {
    BaseERC20Token token = BaseERC20Token(tokenAddr);
    uint256 price = tokenMintPriceMap[tokenAddr];
    if (msg.value != price) {
      revert NotReachedTokenPrice(price, msg.value);
    }
    token.mint(msg.sender);
  }
}
