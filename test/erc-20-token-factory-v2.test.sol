// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { ERC20TokenFactoryV2 } from "../src/contract-factory/erc20-token-factory-v2.sol";
import { ERC20TokenFactoryV2Proxy } from "../src/contract-factory/erc20-token-factory-v2-proxy.sol";
import { BaseERC20Token } from "../src/contract-factory/base-erc-20-token.sol";
import { UUPSUpgradeable } from "../lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";

contract ERC20TokenFactoryV2Test is Test {
  ERC20TokenFactoryV2 public factory;

  function setUp() public {
    ERC20TokenFactoryV2 tokenFactoryV2 = new ERC20TokenFactoryV2();
    bytes memory data = abi.encodeCall(ERC20TokenFactoryV2.initialize, ());
    address tokenFactoryV2ProxyAddr = address(new ERC20TokenFactoryV2Proxy(address(tokenFactoryV2), data));
    factory = ERC20TokenFactoryV2(tokenFactoryV2ProxyAddr);
  }

  function testProxy() public {
    assertEq(factory.owner(), address(this));
    vm.expectRevert(abi.encodeWithSelector(UUPSUpgradeable.UUPSUnauthorizedCallContext.selector));
    factory.proxiableUUID();
  }

  function testDeployInscription(string memory symbol, uint256 maxSupply, uint256 perMint) public {
    vm.assume(perMint <= maxSupply);
    address tokenAddr = factory.deployInscription(symbol, maxSupply, perMint, 100);
    BaseERC20Token token = BaseERC20Token(tokenAddr);
    assertEq(token.symbol(), symbol);
    assertEq(token.owner(), address(factory));
  }
}
