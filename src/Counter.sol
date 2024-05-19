// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {MutexLock} from "./common/MutexLock.sol";

abstract contract Counter is MutexLock {

    uint128 public number;

    /**
     * At same time, only allow one thread increment number, to make the number global unique
     */
    function genTxID() public mutexLock returns (uint128) {
        number++;
        return number;
    }
}
