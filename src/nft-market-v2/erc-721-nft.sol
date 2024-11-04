// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721NFT is ERC721 {
  uint256 public mintedTokenId = 0;

  string private _name;
  string private _symbol;
  bool private _isInitialized = false;

  event ERC721NFT_Minted(address indexed to, uint256 indexed tokenId);

  constructor() ERC721("", "") {}

  function init(string memory _name_, string memory _symbol_) public {
    require(!_isInitialized, "ERC721NFT: already initialized");
    _name = _name_;
    _symbol = _symbol_;
    _isInitialized = true;
  }

  function name() public view override returns(string memory) {
    return _name;
  }

  function symbol() public view override returns(string memory) {
    return _symbol;
  }

  function isAuthorized(address owner, address spender, uint256 tokenId) public view returns(bool) {
    return _isAuthorized(owner, spender, tokenId);
  }

  function freeMint(address to) public {
    _mint(to, mintedTokenId);
    emit ERC721NFT_Minted(to, mintedTokenId);
    mintedTokenId++;
  }
}
