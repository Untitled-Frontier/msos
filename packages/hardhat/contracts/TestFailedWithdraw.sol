// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract TestFailedWithdraw {

    receive() external payable {
        revert('test revert');
    }
}