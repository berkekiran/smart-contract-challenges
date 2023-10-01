// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface ISimpleToken {
    function name() external view returns (string memory);
    function destroy(address to) external;
}

interface IRecovery {}

contract Hack {
    function recover(address sender) external pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x01)));
        address addr = address(uint160(uint256(hash)));
        return addr;
    }
}