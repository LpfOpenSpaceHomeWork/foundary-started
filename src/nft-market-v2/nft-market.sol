// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import { Nonces } from "@openzeppelin/contracts/utils/Nonces.sol";

// 不通过合约上架NFT，而是通过离线签名上架NFT
contract NFTMarketV2 is EIP712, Nonces {

  constructor() EIP712("NFTMarketV2", "1") {}

  error NFTMarketV2_OrderExpired(uint256 deadline, uint256 timestamp);
  error NFTMarketV2_InsufficientPayment(uint256 price, uint256 payment);
  error NFTMarketV2_InvalidSigner(address nftOwner, address signer);
  error NFTMarketV2_NotApproved(address nftAddr, uint256 tokenID);
  event NFTMarketV2_Sold(address indexed nftAddr, uint256 indexed tokenID, address seller, address buyer, uint256 price);


  struct ListingOrderInfo {
    address nftAddr;
    uint256 tokenID;
    uint256 price; // eth
    uint256 listDeadline; // 挂单
  }

  struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
  }

  bytes32 public constant LISTING_ORDER_TYPEHASH = keccak256("ListingOrder(address nftAddr,uint256 tokenID,uint256 price,uint256 listDeadline,uint256 nonce)");

  // nounceKey = bytes32(keccak256(abi.encodePacked(nftAddr, tokenId)
  mapping(bytes32 => uint256) private _nonces;

  function getNonces(address nftAddr, uint256 tokenId) view public returns(uint256) {
    return _nonces[bytes32(keccak256(abi.encodePacked(nftAddr, tokenId)))];
  }

  function _updateNonces(address nftAddr, uint256 tokenId) internal {
    _nonces[bytes32(keccak256(abi.encodePacked(nftAddr, tokenId)))]++;
  }

  function buyNFT(ListingOrderInfo memory order, Signature memory sig) public payable {
    IERC721 nft = IERC721(order.nftAddr);
    address nftOwner = nft.ownerOf(order.tokenID);
    bool isApproved = nft.getApproved(order.tokenID) == address(this) || nft.isApprovedForAll(nftOwner, address(this));
    if (order.listDeadline < block.timestamp) {
      revert NFTMarketV2_OrderExpired(order.listDeadline, block.timestamp);
    }
    if (msg.value < order.price) {
      revert NFTMarketV2_InsufficientPayment(order.price, msg.value);
    }
    if (!isApproved) {
      revert NFTMarketV2_NotApproved(order.nftAddr, order.tokenID);
    }
    uint256 nonce = getNonces(order.nftAddr, order.tokenID);
    bytes32 structHash = keccak256(abi.encode(
      LISTING_ORDER_TYPEHASH,
      order.nftAddr,
      order.tokenID,
      order.price,
      order.listDeadline,
      nonce)
    );
    bytes32 hash = _hashTypedDataV4(structHash);
    address signer = ECDSA.recover(hash, sig.v, sig.r, sig.s);
    if (signer != nftOwner) {
      revert NFTMarketV2_InvalidSigner(nftOwner, signer);
    }
    _updateNonces(order.nftAddr, order.tokenID);
    nft.transferFrom(nftOwner, msg.sender, order.tokenID);
    emit NFTMarketV2_Sold(order.nftAddr, order.tokenID, nftOwner, msg.sender, order.price);
  }
}

