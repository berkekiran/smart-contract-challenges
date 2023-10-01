// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IMagicNum {
    function solver() external view returns (address);
    function setSolver(address) external;
}

interface ISolver {
    function whatIsTheMeaningOfLife() external view returns (uint256);
}

contract Hack {
    constructor(IMagicNum magicNumberContract) {
        bytes memory bytecode = hex"69602a60005260206000f3600052600a6016f3";
        address addr;
        assembly {
            addr := create(0, add(bytecode, 0x20), 0x13)
        }
        require(addr != address(0));
        magicNumberContract.setSolver(addr);
    }
}