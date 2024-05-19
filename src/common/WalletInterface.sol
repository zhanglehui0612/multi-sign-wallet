// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface WalletInterface {

    event Deposit(address indexed sender, uint256 indexed amount);
    event Submit(address indexed submitter, uint128 indexed txid);
    event Approve(address indexed approver, uint32 indexed approved, uint128 indexed txid);
    event Execute(address indexed sender, uint128 indexed txid);
    event Cancel(address indexed sender, uint128 indexed txid);


    error NotOwner(address sender);
    error TransactionNotExists(uint128 txid);
    error TransactionHasDone(uint128 txid);
    error TransactionHasCancelled(uint128 txid);
    error TransactionQuorumNotEnough(uint128 txid, uint32 quorum, uint32 approved);
    error TransactionExecuteFailed(uint128 txid);
    error TransactionCancelFailed(uint128 txid);
    error DuplicatedApproved(address sender, uint128 txid);

}