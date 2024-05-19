// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

abstract contract MutexLock {

    bool private _locked;


    error MutexLockCall();


    constructor() {
        _locked = false;
    }



    modifier mutexLock() {
        _before();
        _;
        _after();
    }




    function _before() internal {
        if (_locked == true) {
            revert MutexLockCall();
        }


        _locked = true;
    }



    function _after() internal {
        _locked = false;
    }
}