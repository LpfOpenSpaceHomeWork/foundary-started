// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

error IllegalTokenId(uint256);

contract SimpleNFT is ERC721 {
  uint256 public constant MAX_SUPPLY = 1000;

  constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {
  }

  function mint(uint256 tokenId) public {
    if (tokenId < MAX_SUPPLY) {
      _safeMint(msg.sender, tokenId);
    } else {
      revert IllegalTokenId(tokenId);
    }
  }
}
