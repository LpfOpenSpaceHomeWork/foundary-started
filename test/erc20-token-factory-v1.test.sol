// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { ERC20TokenFactoryV1 } from "../src/contract-factory/erc20-token-factory-v1.sol";
import { BaseERC20Token } from "../src/contract-factory/base-erc-20-token.sol";

contract ERC20TokenFactoryV1Test is Test {
  ERC20TokenFactoryV1 public factory;

  function setUp() public {
    factory = new ERC20TokenFactoryV1();
  }

  function testDeployInscription(string memory symbol, uint256 maxSupply, uint256 perMint) public {
    vm.assume(perMint <= maxSupply);
    address tokenAddr = factory.deployInscription(symbol, maxSupply, perMint);
    BaseERC20Token token = BaseERC20Token(tokenAddr);
    assertEq(token.symbol(), symbol);
    assertEq(token.owner(), address(factory));
  }

  function testRevertDeployInscriptionInvalidArgs(string memory symbol, uint256 maxSupply, uint256 perMint) public {
    vm.assume(perMint > maxSupply);
    vm.expectRevert(abi.encodeWithSelector(BaseERC20Token.InvalidArgs.selector, maxSupply, perMint));
    factory.deployInscription(symbol, maxSupply, perMint);
  }

  function testMintInscription(string memory symbol, uint256 maxSupply, uint256 perMint) public {
    vm.assume(perMint <= maxSupply);
    address tokenAddr = factory.deployInscription(symbol, maxSupply, perMint);
    address deployer = makeAddr("deployer");
    vm.startPrank(deployer);
    vm.expectEmit(true, true, true, true);
    emit BaseERC20Token.Minted(deployer, perMint);
    factory.mintInscription(tokenAddr);
    vm.stopPrank();
    BaseERC20Token token = BaseERC20Token(tokenAddr);
    assertEq(token.balanceOf(deployer), perMint);
  }

  function testRevertMintInscriptionExceedsMaxSupply(string memory symbol, uint256 maxSupply) public {
    vm.assume(maxSupply > 0 && maxSupply < type(uint256).max / 2);
    uint256 perMint = maxSupply;
    address tokenAddr = factory.deployInscription(symbol, maxSupply, perMint);
    factory.mintInscription(tokenAddr);
    vm.expectRevert(abi.encodeWithSelector(BaseERC20Token.ExceedsMaxSupply.selector));
    factory.mintInscription(tokenAddr);
  }
}
