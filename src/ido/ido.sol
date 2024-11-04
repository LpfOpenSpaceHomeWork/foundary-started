// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TokenPreSale } from "./token-presale.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDO {
  address payable public immutable preSaleImplementation;

  constructor() {
    preSaleImplementation = payable(address(new TokenPreSale()));
  }

  function startPreSale(TokenPreSale.PreSaleInfo memory _preSaleInfo) public returns (address payable) {
    uint tokensToApprove = _preSaleInfo.supply;
    IERC20 token = IERC20(_preSaleInfo.tokenCA);
    require(token.allowance(msg.sender, address(this)) >= tokensToApprove, "Insufficient allowance");
    address payable preSaleCA = payable(Clones.clone(preSaleImplementation));
    token.transferFrom(msg.sender, preSaleCA, tokensToApprove);
    TokenPreSale(preSaleCA).init(_preSaleInfo);
    return preSaleCA;
  }
}


