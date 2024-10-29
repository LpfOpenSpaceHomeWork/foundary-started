// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { SimpleNFTMarket, Listed, Purchased, TransferedTokenAmoutNotMatchPrice } from "../src/nft-market/simple-nft-market.sol";
import { SimpleToken, ISimpleTokenReceiver } from "../src/nft-market/simple-token.sol";
import { SimpleNFT } from "../src/nft-market/simple-nft.sol";

contract SimpleNFTTestHandler is Test {

  SimpleToken public token;
  SimpleNFT public nft;
  SimpleNFTMarket public market;

  constructor(
    SimpleToken _token,
    SimpleNFT _nft,
    SimpleNFTMarket _market
  ) {
    token = _token;
    nft = _nft;
    market = _market;
  }

  function listNFT(uint256 tokenId, uint256 price) public {
    vm.assume(price >= 1 && price <= (10000 * token.decimals()));
    vm.assume(tokenId < nft.MAX_SUPPLY());
    address seller = makeAddr("seller");
    vm.startPrank(seller);
    nft.mint(tokenId);
    nft.approve(address(market), tokenId);
    market.list(tokenId, price);
    vm.stopPrank();
  }

  function buyNFT(uint256 tokenId) public {
    address buyer = makeAddr("buyer");
    if (
      market.listings(tokenId) != 0 &&
      nft.getApproved(tokenId) == address(market) &&
      nft.ownerOf(tokenId) == buyer
    ) {
      uint256 price = market.listings(tokenId);
      vm.startPrank(buyer);
      deal(address(token), buyer, price);
      token.approve(address(market), price);
      market.buyNFT(tokenId);
      vm.stopPrank();
    }
  }

  function listAndBuy(uint256 tokenId, uint256 price) public {
    listNFT(tokenId, price);
    buyNFT(tokenId);
  }
}

contract SimpleNFTMarketTest is Test {
  SimpleToken public token;
  SimpleNFT public nft;
  SimpleNFTMarket public market;
  SimpleNFTTestHandler public handler;

  function setUp() public {
    token = new SimpleToken("SimpleToken", "ST");
    nft = new SimpleNFT("SimpleNFT", "SNFT");
    market = new SimpleNFTMarket(token, nft);
    handler = new SimpleNFTTestHandler(token, nft, market);
  }

  function _assumeArgs( uint256 tokenId, uint256 price) private view {
    // 0.01 <= price <= 10000
    vm.assume(price >= 1 && price <= (10000 * token.decimals()));
    vm.assume(tokenId < nft.MAX_SUPPLY());
  }

  function _assumeArgs(address seller, uint256 tokenId, uint256 price) private view {
    _assumeArgs(tokenId, price);
    // OpenZepplin实现的ERC721要求NFT接收方如果是合约地址，需要实现接收回调，因此这里我们排除转给合约地址的场景
    vm.assume(seller.code.length == 0 && seller != address(0));
  }

  function _assumeArgs(address seller, address buyer, uint256 tokenId, uint256 price) private view {
    _assumeArgs(seller, tokenId, price);
    vm.assume(buyer.code.length == 0 && buyer != address(0));
    vm.assume(buyer != seller);
  }


  function _mintAndListNFT(address seller, uint256 tokenId, uint256 price) private {
    vm.startPrank(seller);
    nft.mint(tokenId);
    nft.approve(address(market), tokenId);
    market.list(tokenId, price);
    vm.stopPrank();
  }

  function _prepareToTestBuyNFT(
    address seller,
    address buyer,
    uint256 tokenId,
    uint256 price
    ) private {
    _assumeArgs(seller, buyer, tokenId, price);
    _mintAndListNFT(seller, tokenId, price);
    deal(address(token), buyer, price);
    deal(address(token), seller, 0);
  }

  // 测试成功挂单的场景
  function testListNFTSuccessfully(
    address seller,
    uint256 tokenId,
    uint256 price
    ) public {
    _assumeArgs(seller, tokenId, price);
    vm.startPrank(seller);
    // seller mint NFT
    nft.mint(tokenId);
    assertEq(nft.ownerOf(tokenId), seller);
    // seller 授权NFT给 market
    nft.approve(address(market), tokenId);
    assertEq(nft.getApproved(tokenId), address(market));
    // seller 在market挂单
    vm.expectEmit(true, true, true, true);
    emit Listed(tokenId, seller, price);
    market.list(tokenId, price);
    assertEq(market.listings(tokenId), price);
    vm.stopPrank();
  }

  // 测试挂单失败的场景
  function testListNFTUnsuccessfully(address seller, uint256 tokenId, uint256 price) public {
    _assumeArgs(seller, tokenId, price);
    vm.startPrank(seller);
    nft.mint(tokenId);
    // case1: 未授权即挂单
    vm.expectRevert("the NFT is not approved to the NFTMarket");
    market.list(tokenId, price);

    // case2: 挂单价为0
    nft.approve(address(market), tokenId);
    vm.expectRevert("price must be larger than 0");
    market.list(tokenId, 0);
    vm.stopPrank();

    // case3: 挂单别人的nft
    address illegalSeller = makeAddr("illegalSeller");
    vm.expectRevert("only the owner of the NFT can list it");
    vm.prank(illegalSeller);
    market.list(tokenId, price);

    // case4: 挂单已经上架的nft
    vm.startPrank(seller);
    vm.expectEmit(true, true, true, true);
    emit Listed(tokenId, seller, price);
    market.list(tokenId, price);
    vm.expectRevert("the NFT has been listed before");
    market.list(tokenId, price);
  }

  // 测试购买成功的场景
  function testBuyNFT(
    address seller,
    address buyer,
    uint256 tokenId,
    uint256 price
    ) public {
    _prepareToTestBuyNFT(seller, buyer, tokenId, price);
    vm.startPrank(buyer);
    // 授权代币
    token.approve(address(market), price);
    assertEq(token.allowance(buyer, address(market)), price);
    vm.expectEmit(true, true, true, true);
    emit Purchased(tokenId, buyer, price);
    // 购买NFT
    market.buyNFT(tokenId);
    assertEq(token.balanceOf(seller), price);
    assertEq(token.balanceOf(buyer), 0);
    assertEq(nft.ownerOf(tokenId), buyer);
    assertEq(market.listings(tokenId), 0);
  }

  // 测试购买NFT失败的场景
  function testBuyNFTUnsuccessfully(
    address seller,
    address buyer,
    uint256 tokenId,
    uint256 price) public {
    _prepareToTestBuyNFT(seller, buyer, tokenId, price);
    // case1: seller未授权nft
    vm.prank(seller);
    nft.approve(address(0), tokenId);
    vm.startPrank(buyer);
    token.approve(address(market), price);
    vm.expectRevert("the NFT is not approved to the NFTMarket");
    market.buyNFT(tokenId);
    vm.stopPrank();
    vm.prank(seller);
    nft.approve(address(market), tokenId);

    // case2: buyer授权的代币数量不足
    vm.startPrank(buyer);
    token.approve(address(market), price - 1);
    vm.expectRevert("the SimpleToken approved to the NFTMarket is not enough");
    market.buyNFT(tokenId);
    vm.stopPrank();

    // case3: nft未上架
    vm.prank(seller);
    market.unlist(tokenId);
    vm.startPrank(buyer);
    token.approve(address(market), price);
    vm.expectRevert("the NFT has not been listed");
    market.buyNFT(tokenId);
    vm.stopPrank();

    // case4: 购买自己的nft
    vm.startPrank(seller);
    market.list(tokenId, price);
    deal(address(token), seller, price);
    token.approve(address(market), price);
    vm.expectRevert("you can not buy your own NFT");
    market.buyNFT(tokenId);
    vm.stopPrank();
  }

  // 测试通过直接给Market合约转账的方式购买NFT的场景
  function testBuyNFTByTransferERC20Token(
    address seller,
    address buyer,
    uint256 tokenId,
    uint256 price
    ) public {
    _prepareToTestBuyNFT(seller, buyer, tokenId, price);
    vm.startPrank(buyer);
    vm.expectEmit(true, true, true, true);
    emit Purchased(tokenId, buyer, price);
    token.transferWithCallback(ISimpleTokenReceiver(market), price, abi.encode(tokenId));
    assertEq(token.balanceOf(seller), price);
    assertEq(token.balanceOf(buyer), 0);
    assertEq(nft.ownerOf(tokenId), buyer);
    assertEq(market.listings(tokenId), 0);
    vm.stopPrank();
  }

  function testBuyNFTByTransferERC20TokenUnsuccessfully(
    address seller,
    address buyer,
    uint256 tokenId,
    uint256 price) public {
    _prepareToTestBuyNFT(seller, buyer, tokenId, price);
    // case1: seller未授权nft
    vm.prank(seller);
    nft.approve(address(0), tokenId);
    vm.startPrank(buyer);
    vm.expectRevert("the NFT is not approved to the NFTMarket");
    token.transferWithCallback(ISimpleTokenReceiver(market), price, abi.encode(tokenId));
    vm.stopPrank();
    vm.prank(seller);
    nft.approve(address(market), tokenId);

    // case2: buyer发送的代币数量不等于price
    vm.assume(price < 10000 * token.decimals());
    vm.startPrank(buyer);
    // 少转
    vm.expectRevert(abi.encodeWithSelector(TransferedTokenAmoutNotMatchPrice.selector, price, price - 1));
    token.transferWithCallback(ISimpleTokenReceiver(market), price - 1, abi.encode(tokenId));
    // 多转
    deal(address(token), buyer, price + 1);
    vm.expectRevert(abi.encodeWithSelector(TransferedTokenAmoutNotMatchPrice.selector, price, price + 1));
    token.transferWithCallback(ISimpleTokenReceiver(market), price + 1, abi.encode(tokenId));
    vm.stopPrank();

    // case3: nft未上架
    vm.prank(seller);
    market.unlist(tokenId);
    vm.startPrank(buyer);
    vm.expectRevert("the NFT has not been listed");
    token.transferWithCallback(ISimpleTokenReceiver(market), price, abi.encode(tokenId));
    vm.stopPrank();

    // case4: 购买自己的nft
    vm.startPrank(seller);
    market.list(tokenId, price);
    deal(address(token), seller, price);
    vm.expectRevert("you can not buy your own NFT");
    token.transferWithCallback(ISimpleTokenReceiver(market), price, abi.encode(tokenId));
    vm.stopPrank();
  }

  // // 不可变测试
  // function invariantMarketTokenBalance() public {
  //   assertEq(token.balanceOf(address(market)), 0);
  // }
}
