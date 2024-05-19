// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Counter} from "../src/Counter.sol";
import {Transaction} from "../src/structs/Transaction.sol";
import {TransactionStatus} from "../src/enums/TransactionStatus.sol";
import {MultiSignatureWallet} from "../src/MultiSignatureWallet.sol";
import {OtherContract} from "./OtherContract.sol";
import {WalletInterface} from "../src/common/WalletInterface.sol";

contract MultiSignatureWalletTest is Test {
    MultiSignatureWallet wallet;
    OtherContract otherContract;
    address owner;
    address owner1;
    address owner2;
    address other;
    bytes depositsFunc;
    bytes withdrawFunc;

    function setUp() public {
        otherContract = OtherContract(
            0x5FbDB2315678afecb367f032d93F642f64180aa3
        );
        owner = makeAddr("owner");
        owner1 = makeAddr("owner1");
        owner2 = makeAddr("owner2");
        other = makeAddr("other");

        deal(owner, 100 ether);
        deal(owner1, 100 ether);
        deal(owner2, 100 ether);
        deal(other, 100 ether);

        vm.startPrank(owner);
        wallet = new MultiSignatureWallet();
        wallet.addOwner(owner1);
        wallet.addOwner(owner2);
        wallet.setQuorum(2);
        deal(address(wallet), 100 ether);

        vm.stopPrank();
        depositsFunc = abi.encodeWithSignature("deposit()");
        withdrawFunc = abi.encodeWithSignature(
            "withdraw(uint256)",
            100000000000000
        );
    }

    function testSubmit() public {
        vm.startPrank(owner);
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            1 ether,
            depositsFunc
        );
        vm.stopPrank();
    }

    function testApprove() public {
        vm.startPrank(owner);
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            1 ether,
            depositsFunc
        );
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            2 ether,
            depositsFunc
        );
        vm.stopPrank();

        vm.startPrank(other);
        vm.expectRevert(
            abi.encodeWithSelector(WalletInterface.NotOwner.selector, other)
        );
        wallet.approve(1);
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.TransactionNotExists.selector,
                10
            )
        );
        wallet.approve(10);

        wallet.approve(1);
        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.DuplicatedApproved.selector,
                owner,
                1
            )
        );
        wallet.approve(1);

        vm.stopPrank();
    }

    function testTransaction() public {
        vm.startPrank(owner);
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            1 ether,
            depositsFunc
        );
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            2 ether,
            depositsFunc
        );
        wallet.approve(1);
        wallet.approve(2);
        vm.stopPrank();

        vm.startPrank(other);
        vm.expectRevert(
            abi.encodeWithSelector(WalletInterface.NotOwner.selector, other)
        );
        wallet.execute(1);
        vm.stopPrank();

        vm.startPrank(owner1);
        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.TransactionNotExists.selector,
                10
            )
        );
        wallet.execute(10);

        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.TransactionQuorumNotEnough.selector,
                1,
                2,
                1
            )
        );
        wallet.execute(1);

        wallet.approve(1);
        wallet.execute(1);

        wallet.approve(2);
        vm.stopPrank();

        vm.startPrank(owner2);
        wallet.cancel(2);

        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.TransactionHasCancelled.selector,
                2
            )
        );
        wallet.execute(2);
        vm.stopPrank();
    }

    function testCancel() public {
        vm.startPrank(owner);
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            1 ether,
            depositsFunc
        );
        wallet.approve(1);
        vm.stopPrank();

        vm.startPrank(owner1);
        wallet.approve(1);
        vm.stopPrank();

        vm.startPrank(owner2);
        wallet.execute(1);

        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.TransactionHasDone.selector,
                1
            )
        );
        wallet.cancel(1);
        vm.stopPrank();

        vm.startPrank(owner);
        wallet.submit(
            0x5FbDB2315678afecb367f032d93F642f64180aa3,
            0,
            withdrawFunc
        );
        wallet.approve(2);
        vm.stopPrank();

        vm.startPrank(owner1);
        wallet.approve(2);
        vm.stopPrank();

        vm.startPrank(owner2);
        wallet.cancel(2);

        vm.expectRevert(
            abi.encodeWithSelector(
                WalletInterface.TransactionHasCancelled.selector,
                2
            )
        );
        wallet.cancel(2);
        vm.stopPrank();
    }
}
