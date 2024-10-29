// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { BaseERC20Token } from "./base-erc-20-token.sol";

contract ERC20TokenFactoryV1 {
  event InscriptionDeployed(string indexed symbol, address indexed tokenAddr);

  function deployInscription(string calldata symbol, uint256 maxSupply, uint256 perMint) public returns(address) {
    BaseERC20Token deployedToken = new BaseERC20Token();
    deployedToken.init(symbol, maxSupply, perMint);
    address deployedTokenAddr = address(deployedToken);
    emit InscriptionDeployed(symbol, deployedTokenAddr);
    return deployedTokenAddr;
  }

  function mintInscription(address tokenAddr) public {
    BaseERC20Token token = BaseERC20Token(tokenAddr);
    token.mint(msg.sender);
  }
}
