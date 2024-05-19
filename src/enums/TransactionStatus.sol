// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

enum TransactionStatus {
    INIT,
    APPENDING,
    CANCELLED,
    DONE
}