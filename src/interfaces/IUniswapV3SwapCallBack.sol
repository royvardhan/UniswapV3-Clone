pragma solidity ^0.8.23;

interface IUniswapV3SwapCallback {

    function uniswapV3SwapCallback(
        int256 amount0,
        int256 amount1
    ) external;
}