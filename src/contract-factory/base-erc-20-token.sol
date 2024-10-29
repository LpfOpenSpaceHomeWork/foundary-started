// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract BaseERC20Token is ERC20, Ownable {
  bool public inited = false;
  string private _token_symbol = "";
  uint256 private _maxSupply = 0;
  uint256 private _perMint = 0;

  error InvalidArgs(uint256 maxSupply, uint256 perMint);
  error NotAllowedToInitMultipleTimes();
  error ExceedsMaxSupply();

  event Minted(address indexed account, uint256 indexed amount);
  event Inited(string indexed token_symbol, uint256 indexed maxSupply, uint256 indexed perMint);

  constructor() ERC20("BaseERC20Token", "BaseERC20Token") Ownable(msg.sender) {

  }

  function symbol() public override view returns(string memory) {
    return _token_symbol;
  }

  function init(string calldata token_symbol, uint256 maxSupply, uint256 perMint) public {
    if (inited) {
      revert NotAllowedToInitMultipleTimes();
    }
    if (perMint > maxSupply) {
      revert InvalidArgs(maxSupply, perMint);
    }
    _token_symbol = token_symbol;
    _maxSupply = maxSupply;
    _perMint = perMint;
    transferOwnership(msg.sender);
    inited = true;
    emit Inited(token_symbol, maxSupply, perMint);
  }

  function mint(address account) public onlyOwner {
    if (totalSupply() + _perMint > _maxSupply) {
      revert ExceedsMaxSupply();
    }
    _mint(account, _perMint);
    emit Minted(account, _perMint);
  }
}
