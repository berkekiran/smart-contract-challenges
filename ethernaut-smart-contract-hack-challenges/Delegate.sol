// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IDelegate {
    function pwn() external;
    function owner() external view returns (address);
}