// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
contract OtherContract {
    mapping (address => uint256) balances;

    function deposit() payable external {
        balances[msg.sender] = msg.value;
        console.log("OtherContract deposit >>>>>", balances[msg.sender]);
    }

    function withdraw(uint256 amount) external {
        balances[msg.sender] -= amount;
        msg.sender.call{value: amount}("");
        console.log("OtherContract withdraw >>>>>", balances[msg.sender]);
    }
}