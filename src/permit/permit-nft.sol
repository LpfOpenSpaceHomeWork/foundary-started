// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";
import { SimpleNFT } from "../nft-market/simple-nft.sol";

error NFTPermitExpiredSignature(uint256 deadline);
error NFTPermitInvalidSigner(address signer, address owner);

contract PermitNFT is SimpleNFT, EIP712, Nonces {
  constructor(string memory _name, string memory _symbol)
    SimpleNFT(_name, _symbol)
    EIP712("PermitAppoveNFT", "1") {
  }

  bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address to,uint256 tokenId,uint256 nonce,uint256 deadline)");

  function buildPermitArgsHashTypedDataV4(
    address to,
    uint256 tokenId,
    uint256 deadline
  ) public view returns(bytes32) {
    address owner = ownerOf(tokenId);
    bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, to, tokenId, nonces(owner), deadline));
    bytes32 hash = _hashTypedDataV4(structHash);
    return hash;
  }

  function permit(
    address to,
    uint256 tokenId,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public {
    if (block.timestamp > deadline) {
      revert NFTPermitExpiredSignature(deadline);
    }
    address owner = ownerOf(tokenId);
    bytes32 hash = buildPermitArgsHashTypedDataV4(to, tokenId, deadline);
    address signer = ECDSA.recover(hash, v, r, s);
    if (signer != owner) {
        revert NFTPermitInvalidSigner(signer, owner);
    }
    _useNonce(owner);
    _approve(to, tokenId, owner);
  }
}
