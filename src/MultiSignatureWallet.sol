// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Counter} from "./Counter.sol";
import {Transaction} from "./structs/Transaction.sol";
import {TransactionStatus} from "./enums/TransactionStatus.sol";
import {WalletInterface} from "./common/WalletInterface.sol";
import {MutexLock} from "./common/MutexLock.sol";

contract MultiSignatureWallet is Counter, WalletInterface {
    uint16 quorum;

    mapping(address => bool) owners;

    mapping(uint128 => Transaction) transactions;

    mapping(uint128 => mapping(address => bool)) approveRecords;

    constructor() {
        owners[msg.sender] = true;
    }

    modifier admin() {
        if (!owners[msg.sender]) revert NotOwner(msg.sender);
        _;
    }

    /*
     * Submmit the transaction
     * @param to 
     * @param amount 
     * @param data 
     */
    function submit(address to, uint128 amount, bytes calldata data) external  {
        // generate global unuqie txid
        uint128 txid = genTxID();
        Transaction memory transaction = Transaction(
            txid,
            amount,
            0,
            to,
            data,
            TransactionStatus.INIT
        );

        transactions[txid] = transaction;
        emit Submit(msg.sender, amount);
    }



    /*
     * Owner approve transaction
     * @param txid 
     */
    function approve(uint128 txid) external admin {
        // check transaction
        _check(txid);

        // if this onwer has approved, not allow approve once more
        if (approveRecords[txid][msg.sender]) {
            revert DuplicatedApproved(msg.sender, txid);
        }

        // increment the approved number
        transactions[txid].approved += 1;

        // if transaction is init status, switch to appending status
        if (transactions[txid].status == TransactionStatus.INIT) {
            transactions[txid].status = TransactionStatus.APPENDING;
        }

        // update sender has approved
        approveRecords[txid][msg.sender] = true;

        emit Approve(msg.sender, transactions[txid].approved, txid);
    }



    /*
     * Execute transaction
     * @param txid 
     */
    function execute(uint128 txid) external admin mutexLock {
        // check transaction
        _check(txid);

        // check if have enough onwer approved, if not enough, can not execute transaction
        if (transactions[txid].approved < quorum) {
            revert TransactionQuorumNotEnough(txid, quorum, transactions[txid].approved);
        }

        (bool success, ) = transactions[txid].to.call{value: transactions[txid].amount}(
            transactions[txid].data
        );

        if (!success) {
            revert TransactionExecuteFailed(txid);
        }
        transactions[txid].status = TransactionStatus.DONE;
        emit Execute(msg.sender, txid);
    }



    /*
     * Cancel transaction
     * @param txid 
     */
    function cancel(uint128 txid) external admin mutexLock {
        // check transaction
        _check(txid);

        // delete transaction
        //delete transactions[txid];
        transactions[txid].status = TransactionStatus.CANCELLED;

        emit Cancel(msg.sender, txid);
    }



    /*
     * allow user add owner
     * @param _owner 
     */
    function addOwner(address _owner) external admin {
        owners[_owner] = true;
    }



    /*
     * allow user can set the quorum
     * @param _quorum 
     */
    function setQuorum(uint16 _quorum) external admin {
        quorum = _quorum;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }



    function _check(uint128 txid) internal {
        Transaction storage transaction = transactions[txid];
        if (transaction.txid == 0) {
            revert TransactionNotExists(txid);
        }

        if (transaction.status == TransactionStatus.DONE) {
            revert TransactionHasDone(txid);
        }

        if (transaction.status == TransactionStatus.CANCELLED) {
            revert TransactionHasCancelled(txid);
        }
    }
}