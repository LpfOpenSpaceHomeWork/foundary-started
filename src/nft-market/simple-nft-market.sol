// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { SimpleToken, ISimpleTokenReceiver } from "./simple-token.sol";
import { SimpleNFT } from "./simple-nft.sol";

error TransferedTokenAmoutNotMatchPrice(uint256 price, uint256 transferedTokenAmount);

event Listed(uint256 indexed tokenId, address indexed seller, uint256 price);
event Unlisted(uint256 indexed tokenId, address indexed owner);
event Purchased(uint256 indexed tokenId, address indexed buyer, uint256 price);

contract SimpleNFTMarket is ISimpleTokenReceiver {
  SimpleToken public immutable token;
  SimpleNFT public immutable nft;
  // tokenID => price
  mapping(uint256 => uint256) public listings;

  constructor(SimpleToken _tokenAddr, SimpleNFT _nftAddr) {
    token = _tokenAddr;
    nft = _nftAddr;
  }

  modifier approvedNFT(uint256 tokenId) {
    address nftOwner = nft.ownerOf(tokenId);
    require(
      _isNFTApproved(tokenId),
      "the NFT is not approved to the NFTMarket"
    );
    _;
  }

  modifier allowanedToken(address account, uint256 amount) {
    uint256 _allownedToken = token.allowance(account, address(this));
    require(
      _allownedToken >= amount,
      ("the SimpleToken approved to the NFTMarket is not enough")
    );
    _;
  }

  modifier onlyNFTListed(uint256 tokenId) {
    require(_isNFTListed(tokenId), "the NFT has not been listed");
    _;
  }

  modifier onlyNFTOwner(uint256 tokenId) {
    require(nft.ownerOf(tokenId) == msg.sender, "only the owner of the NFT can list it");
    _;
  }

  function _isNFTApproved(uint256 tokenId) private view returns(bool) {
    address nftOwner = nft.ownerOf(tokenId);
    return (
      nftOwner == address(this) ||
      nft.isApprovedForAll(nftOwner, address(this)) ||
      nft.getApproved(tokenId) == address(this)
    );
  }

  function _isNFTListed(uint256 tokenId) private view returns(bool) {
    return listings[tokenId] > 0;
  }

  function _list(uint256 tokenId, uint256 price) internal {
    require(price > 0, "price must be larger than 0");
    require(listings[tokenId] == 0, "the NFT has been listed before");
    listings[tokenId] = price;
    emit Listed(tokenId, nft.ownerOf(tokenId), price);
  }

  function list(uint256 tokenId, uint256 price) external
    approvedNFT(tokenId)
    onlyNFTOwner(tokenId) {
      _list(tokenId, price);
  }

  function unlist(uint256 tokenId) external
    onlyNFTOwner(tokenId)
    onlyNFTListed(tokenId) {
    delete listings[tokenId];
    emit Unlisted(tokenId, msg.sender);
  }

  function _buyNFT(address buyer, uint256 tokenId) internal
    approvedNFT(tokenId)
    onlyNFTListed(tokenId) {
      uint256 price = listings[tokenId];
      address seller = nft.ownerOf(tokenId);
      require(seller != buyer, "you can not buy your own NFT");
      token.transferFrom(buyer, seller, price);
      nft.safeTransferFrom(seller, buyer, tokenId);
      delete listings[tokenId];
      emit Purchased(tokenId, msg.sender, price);
  }

  function buyNFT(uint256 tokenId) external
    allowanedToken(msg.sender, listings[tokenId]) {
      _buyNFT(msg.sender, tokenId);
  }

  function tokensReceived(address from, uint256 amount, bytes calldata data) external {
    require(msg.sender == address(token), "only the SimpleToken Contract can call the hook");
    (uint256 tokenId) = abi.decode(data, (uint256));
    uint256 price = listings[tokenId];
    address seller = nft.ownerOf(tokenId);
    address buyer = from;
    require(_isNFTApproved(tokenId), "the NFT is not approved to the NFTMarket");
    require(_isNFTListed(tokenId), "the NFT has not been listed");
    require(seller != buyer, "you can not buy your own NFT");
    if (amount != price) {
        revert TransferedTokenAmoutNotMatchPrice(price, amount);
    }
    token.transfer(seller, price);
    nft.safeTransferFrom(seller, buyer, tokenId);
    delete listings[tokenId];
    emit Purchased(tokenId, buyer, price);
  }
}
