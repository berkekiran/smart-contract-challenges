// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

// We can find the password in constructor inputs
interface IVault {
    function locked() external view returns (bool);
    function unlock(bytes32 password) external;
}