// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SimpleToken } from "../nft-market/simple-token.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract PermitToken is SimpleToken, ERC20Permit {
  constructor(string memory _name, string memory _symbol)
    SimpleToken(_name, _symbol)
    ERC20Permit("PermitApproveToken") {

  }

  function decimals() public pure override(SimpleToken, ERC20) returns(uint8) {
    return 2;
  }

  bytes32 private constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

  function buildPermitArgsHashTypedDataV4(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline
  ) public view returns(bytes32) {
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces(owner), deadline));
    bytes32 hash = _hashTypedDataV4(structHash);
    return hash;
  }
}
