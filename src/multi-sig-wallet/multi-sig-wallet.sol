// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

error SignersNumberCanNotBeLessThanThreshold(uint256 signersNumber, uint256 threshold);
error OnlySignerCanOperate(address msgSender);
error OnlyProposerCanOperate(uint256 proposalId, address msgSender, address proposer);
error ProposalCanOnlyBeConfirmedOnce(uint256 proposalId, address signer);
error ProposalNotExsits(uint256 proposalId);
error ProposalCanNotBeExcuted(uint256 proposalId, uint256 threshold, uint256 confirmedTimes);
error FailedToExcuteProposal(uint256 proposalId);
error SignersCanNotBeRepeated(address signer);

struct Proposal {
  bytes callData; // 交易数据
  address to; // 交易接收方
  uint256 value; // 交易数额
  address[] confirmers; // 确认者
  address proposer; // 提出者
}

contract MultiSigWallet {
  uint256 public immutable threshold;
  uint256 nounce;
  mapping(address => bool) isSigner;
  mapping(uint256 => Proposal) proposals;
  mapping(uint256 => mapping(address => bool)) isSignerConfirmedProposal;


  constructor(address[] memory _signers, uint256 _threshold) {
    if (_signers.length < _threshold) {
      revert SignersNumberCanNotBeLessThanThreshold(_signers.length, _threshold);
    }
    threshold = _threshold;
    for (uint256 i = 0 ; i < _signers.length; i++) {
      if (isSigner[_signers[i]]) {
        revert SignersCanNotBeRepeated(_signers[i]);
      }
      isSigner[_signers[i]] = true;
    }
  }

  modifier onlySigner() {
    if (!isSigner[msg.sender]) {
      revert OnlySignerCanOperate(msg.sender);
    }
    _;
  }

  modifier existsProposal(uint256 proposalId) {
    if (proposals[proposalId].proposer == address(0)) {
      revert ProposalNotExsits(proposalId);
    }
    _;
  }

  function _confirmProposal(uint256 proposalId) internal {
    isSignerConfirmedProposal[proposalId][msg.sender] = true;
    proposals[proposalId].confirmers.push(msg.sender);
  }

  function makeProposal(address to, bytes calldata callData, uint256 value) public
    onlySigner
    returns(uint256) {
      proposals[nounce++] = Proposal({
        callData: callData,
        to: to,
        value: value,
        confirmers: new address[](0),
        proposer: msg.sender
      });
      _confirmProposal(nounce);
      return nounce;
  }

  function confirmProposal(uint256 proposalId) public
    onlySigner
    existsProposal(proposalId) {
      if (isSignerConfirmedProposal[proposalId][msg.sender]) {
        revert ProposalCanOnlyBeConfirmedOnce(proposalId, msg.sender);
      }
      _confirmProposal(proposalId);
  }

  function excuteProposal(uint256 proposalId) public
    existsProposal(proposalId)
    returns(bytes memory) {
      Proposal memory proposal = proposals[proposalId];
      if (proposal.confirmers.length < threshold) {
        revert ProposalCanNotBeExcuted(proposalId, threshold, proposal.confirmers.length);
      }
      (bool success, bytes memory data) = proposal.to.call{value: proposal.value}(proposal.callData);
      if (!success) {
        revert FailedToExcuteProposal(proposalId);
      }
      delete proposals[proposalId];
      for (uint256 i = 0; i < proposal.confirmers.length; i++) {
        delete isSignerConfirmedProposal[proposalId][proposal.confirmers[i]];
      }
      return data;
  }
}
