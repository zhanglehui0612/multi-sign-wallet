// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {TransactionStatus} from "../enums/TransactionStatus.sol";

struct Transaction {
    uint128 txid;
    uint128 amount;
    uint32 approved;
    address to;
    bytes data;
    TransactionStatus status;  
}