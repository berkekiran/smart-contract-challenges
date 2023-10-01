// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IFallback {
    function owner() external view returns (address);
    function contributions(address) external view returns (uint256);
    function contribute() external payable;
    function withdraw() external;
}