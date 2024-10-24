// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import { Test } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { PermitNFTMarket, Signature } from "../src/permit/permit-nft-market.sol";
import { PermitToken } from "../src/permit/permit-token.sol";
import { PermitNFT, NFTPermitInvalidSigner, NFTPermitExpiredSignature } from "../src/permit/permit-nft.sol";


contract PermitNFTMarketTest is Test {
  PermitToken public token;
  PermitNFT public nft;
  PermitNFTMarket public market;

  function setUp() public {
    token = new PermitToken("PermitToken", "PT");
    nft = new PermitNFT("PermitNFT", "PNFT");
    market = new PermitNFTMarket(token, nft);
  }

  function _assumeArgs(uint256 tokenId, uint256 price) private view {
    vm.assume(price >= 1 && price <= (10000 * token.decimals()));
    vm.assume(tokenId < nft.MAX_SUPPLY());
  }

  function testPermitList(string memory sellerName, uint256 tokenId, uint256 price) public {
    _assumeArgs(tokenId, price);
    Vm.Wallet memory sellerWallet = vm.createWallet(sellerName);
    address sellerAddr = sellerWallet.addr;
    vm.prank(sellerAddr);
    nft.mint(tokenId);
    assertEq(nft.ownerOf(tokenId), sellerAddr);
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = nft.buildPermitArgsHashTypedDataV4(address(market), tokenId, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerWallet, digest);
    market.permitList(tokenId, price, deadline, Signature(v, r, s));
    assertEq(market.listings(tokenId), price);
  }

  function testRevertPermitListNFTInvalidSigner(string memory sellerName, string memory signerName, uint256 tokenId, uint256 price) public {
    _assumeArgs(tokenId, price);
    Vm.Wallet memory sellerWallet = vm.createWallet(sellerName);
    Vm.Wallet memory signerWallet = vm.createWallet(signerName);
    address sellerAddr = sellerWallet.addr;
    address signerAddr = signerWallet.addr;
    vm.assume(sellerAddr != signerAddr);
    vm.prank(sellerAddr);
    nft.mint(tokenId);
    assertEq(nft.ownerOf(tokenId), sellerAddr);
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = nft.buildPermitArgsHashTypedDataV4(address(market), tokenId, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerWallet, digest);
    vm.expectRevert(abi.encodeWithSelector(NFTPermitInvalidSigner.selector, signerAddr, sellerAddr));
    market.permitList(tokenId, price, deadline, Signature(v, r, s));
    assertEq(market.listings(tokenId), 0);
  }

  function testRevertPermitListNFTExpiredSignature(string memory sellerName, uint256 tokenId, uint256 price) public {
    _assumeArgs(tokenId, price);
    Vm.Wallet memory sellerWallet = vm.createWallet(sellerName);
    address sellerAddr = sellerWallet.addr;
    vm.prank(sellerAddr);
    nft.mint(tokenId);
    assertEq(nft.ownerOf(tokenId), sellerAddr);
    uint256 deadline = 1 days;
    vm.warp(2 days);
    bytes32 digest = nft.buildPermitArgsHashTypedDataV4(address(market), tokenId, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerWallet, digest);
    vm.expectRevert(abi.encodeWithSelector(NFTPermitExpiredSignature.selector, deadline));
    market.permitList(tokenId, price, deadline, Signature(v, r, s));
    assertEq(market.listings(tokenId), 0);
  }

  function testRevertPermitListUseSignatureMultipleTimes(string memory sellerName, uint256 tokenId, uint256 price) public {
    _assumeArgs(tokenId, price);
    Vm.Wallet memory sellerWallet = vm.createWallet(sellerName);
    address sellerAddr = sellerWallet.addr;
    vm.prank(sellerAddr);
    nft.mint(tokenId);
    assertEq(nft.ownerOf(tokenId), sellerAddr);
    uint256 deadline = block.timestamp + 1 days;
    bytes32 digest = nft.buildPermitArgsHashTypedDataV4(address(market), tokenId, deadline);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerWallet, digest);
    market.permitList(tokenId, price, deadline, Signature(v, r, s));
    assertEq(market.listings(tokenId), price);
    vm.prank(sellerAddr);
    market.unlist(tokenId);
    assertEq(market.listings(tokenId), 0);
    // 此时nonce已经变了，算出来的verifyingDigest和digest是不一样的
    bytes32 verifyingDigest = nft.buildPermitArgsHashTypedDataV4(address(market), tokenId, deadline);
    address invalidSigner = ECDSA.recover(verifyingDigest, v, r, s);
    vm.expectRevert(abi.encodeWithSelector(NFTPermitInvalidSigner.selector, invalidSigner, sellerAddr));
    market.permitList(tokenId, price, deadline, Signature(v, r, s));
    assertEq(market.listings(tokenId), 0);
  }

  function _mintAndlistNFT(address sellerAddr, address buyerAddr, uint256 tokenId, uint256 price) private {
    vm.startPrank(sellerAddr);
    nft.mint(tokenId);
    nft.approve(address(market), tokenId);
    market.list(tokenId, price);
    vm.stopPrank();
    deal(address(token), buyerAddr, price);
  }

  /**
  * ERC20Permit token的相关异常测试参考permit-token-bank.test.sol，这里在permitBuy中不测了，只测一下白名单签名异常的情况
  */

  function testPermitBuy(string memory buyerName, string memory sellerName, uint256 tokenId, uint256 price) public {
    _assumeArgs(tokenId, price);
    Vm.Wallet memory sellerWallet = vm.createWallet(sellerName);
    Vm.Wallet memory buyerWallet = vm.createWallet(buyerName);
    address sellerAddr = sellerWallet.addr;
    address buyerAddr = buyerWallet.addr;
    vm.assume(sellerAddr != buyerAddr);
    _mintAndlistNFT(sellerAddr, buyerAddr, tokenId, price);
    assertEq(nft.ownerOf(tokenId), sellerAddr);
    uint256 deadline = block.timestamp + 1 days;
    bytes32 sellerDigest = market.buildPermitArgsHashTypedDataV4(buyerAddr, tokenId, deadline);
    (uint8 vSellerSig, bytes32 rSellerSig, bytes32 sSellerSig) = vm.sign(sellerWallet, sellerDigest);
    Signature memory sellerPermitSig = Signature(vSellerSig, rSellerSig, sSellerSig);

    bytes32 buyerDigest = token.buildPermitArgsHashTypedDataV4(buyerAddr, address(market), price, deadline);
    (uint8 vBuyerSig, bytes32 rBuyerSig, bytes32 sBuyerSig) = vm.sign(buyerWallet, buyerDigest);
    Signature memory buyerPermitSig = Signature(vBuyerSig, rBuyerSig, sBuyerSig);

    market.permitBuyNFT(buyerAddr, tokenId, deadline, sellerPermitSig, buyerPermitSig);
    assertEq(nft.ownerOf(tokenId), buyerAddr);
  }
}
