// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

// _key is 0x0a0328a80759b7bb300b55618f78e8e8
interface IPrivacy {
    function locked() external view returns (bool);
    function unlock(bytes16 _key) external;
}