// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { PermitToken } from "./permit-token.sol";
import { PermitNFT } from "./permit-nft.sol";
import { SimpleNFTMarket } from "../nft-market/simple-nft-market.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

error ExpiredSignature(uint256 deadline);
error InvalidSigner(address signer, address nftOwner);

struct Signature {
  uint8 v;
  bytes32 r;
  bytes32 s;
}

contract PermitNFTMarket is SimpleNFTMarket, EIP712 {
  PermitToken public immutable permitToken;
  PermitNFT public immutable permitNFT;
  constructor(PermitToken _permitToken, PermitNFT _permitNFT)
    SimpleNFTMarket(_permitToken, _permitNFT)
    EIP712("PermitBuyNFT", "1") {
      permitToken = _permitToken;
      permitNFT = _permitNFT;
  }

  // nounceKey = bytes32(keccak256(abi.encodePacked(seller,buyer,tokenId))
  // 由于可能会有多个卖家给多个买家分发多个签名，所以这里我们不使用OpenZepplin提供的Nonces合约，而是把nonce的粒度限定为一次交易的nonce
  mapping(bytes32 => uint256) private _nonces;

  function _getNonces(address seller, address buyer, uint256 tokenId) view internal returns(uint256) {
    return _nonces[bytes32(keccak256(abi.encodePacked(seller, buyer, tokenId)))];
  }

  function _updateNonces(address seller, address buyer, uint256 tokenId) internal {
    _nonces[bytes32(keccak256(abi.encodePacked(seller, buyer, tokenId)))]++;
  }

  bytes32 private constant PERMIT_TYPEHASH =
        keccak256("Permit(address buyer,uint256 tokenId,uint256 nonce,uint256 deadline)");

  function permitList(
    uint256 tokenId,
    uint256 price,
    uint256 deadline,
    Signature calldata signature
  ) public {
    permitNFT.permit(
      address(this),
      tokenId,
      deadline,
      signature.v,
      signature.r,
      signature.s
    );
    _list(tokenId, price);
  }

  function buildPermitArgsHashTypedDataV4(
    address buyer,
    uint256 tokenId,
    uint256 deadline
  ) public view returns(bytes32) {
    address seller = nft.ownerOf(tokenId);
    bytes32 structHash = keccak256(abi.encode(
        PERMIT_TYPEHASH,
        buyer,
        tokenId,
        _getNonces(seller, buyer, tokenId),
        deadline)
      );
    bytes32 hash = _hashTypedDataV4(structHash);
    return hash;
  }

  function permitBuyNFT(
    address buyer,
    uint256 tokenId,
    uint256 deadline,
    Signature calldata sellerPermitSig,
    Signature calldata buyerPermitSig
  ) public {
    if (block.timestamp > deadline) {
      revert ExpiredSignature(deadline);
    }
    // 这里的seller就是项目方
    address seller = permitNFT.ownerOf(tokenId);
    bytes32 hash = buildPermitArgsHashTypedDataV4(buyer, tokenId, deadline);
    address signer = ECDSA.recover(hash, sellerPermitSig.v, sellerPermitSig.r, sellerPermitSig.s);
    if (signer != seller) {
      revert InvalidSigner(signer, seller);
    }
    _updateNonces(seller, buyer, tokenId);
    uint256 price = listings[tokenId];
    permitToken.permit(
      buyer,
      address(this),
      price,
      deadline,
      buyerPermitSig.v,
      buyerPermitSig.r,
      buyerPermitSig.s
    );
    _buyNFT(buyer, tokenId);
  }
}
