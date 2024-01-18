pragma solidity ^0.8.23;

interface IUniswapV3MintCallback {
    function uniswapV3MintCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    function uniswapV3SwapCallback(
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}
