pragma solidity ^0.8.23;

import {Tick} from "./libs/Tick.sol";
import {Position} from "./libs/Position.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IUniswapV3MintCallback} from "./interfaces/IUniswapV3MintCallback.sol";
import {IUniswapV3SwapCallback} from "./interfaces/IUniswapV3SwapCallback.sol";
import {TickBitmap} from "./libs/TickBitmap.sol";

contract UniswapV3Pool {
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using TickBitmap for mapping(int16 => uint256);
    mapping(int16 => uint256) public tickBitmap;

    event Mint(
        address indexed sender,
        address indexed owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amountLiquidity,
        uint256 amount0,
        uint256 amount1
    );

    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    int24 internal constant MIN_TICK = -887272;
    int24 internal constant MAX_TICK = -MIN_TICK;

    //Pool Tokens

    address public immutable token0;
    address public immutable token1;

    struct Slot0 {
        // Current sqrt(P)
        uint160 sqrtPriceX96;
        // Current tick
        int24 tick;
    }

    struct CallbackData {
        address token0;
        address token1;
        address payer;
    }

    Slot0 public slot0;

    uint128 public liquidity;

    mapping(int24 => Tick.Info) public ticks;
    mapping(bytes32 => Position.Info) public positions;

    constructor(
        address _token0,
        address _token1,
        uint160 _sqrtPriceX96,
        int24 _tick
    ) {
        token0 = _token0;
        token1 = _token1;

        slot0 = Slot0({sqrtPriceX96: _sqrtPriceX96, tick: _tick});
    }

    function mint(
        address owner,
        int24 lowerTick,
        int24 upperTick,
        uint128 amountLiquidity,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1) {
        if (
            lowerTick >= upperTick ||
            lowerTick < MIN_TICK ||
            upperTick > MAX_TICK
        ) {
            revert("UniswapV3Pool: INVALID_RANGE");
        }

        if (amountLiquidity == 0) {
            revert("UniswapV3Pool: ZERO_LIQUIDITY");
        }

        ticks.update(lowerTick, amountLiquidity);
        ticks.update(upperTick, amountLiquidity);

        Position.Info storage position = positions.get(
            owner,
            lowerTick,
            upperTick
        );
        position.update(amountLiquidity);

        uint256 balance0Before;
        uint256 balance1Before;

        amount0 = 0.998976618347425280 ether; // TODO: replace with calculation
        amount1 = 5000 ether; // TODO: replace with calculation

        liquidity += uint128(amountLiquidity);

        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();

        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(
            amount0,
            amount1,
            data
        );

        if (amount0 > 0 && balance0Before + amount0 > balance0()) {
            revert("UniswapV3Pool: EXCESSIVE_INPUT_AMOUNT");
        }

        if (amount1 > 0 && balance1Before + amount1 > balance1()) {
            revert("UniswapV3Pool: EXCESSIVE_INPUT_AMOUNT");
        }

        emit Mint(
            msg.sender,
            owner,
            lowerTick,
            upperTick,
            amountLiquidity,
            amount0,
            amount1
        );
    }

    function swap(
        address recipient,
        bytes calldata data
    ) public returns (int256 amount0, int256 amount1) {
        int24 nextTick = 85184;
        uint160 nextPrice = 5604469350942327889444743441197;

        amount0 = -0.008396714242162444 ether;
        amount1 = 42 ether;

        (slot0.tick, slot0.sqrtPriceX96) = (nextTick, nextPrice);

        IERC20(token0).transfer(recipient, uint256(-amount0));

        uint256 balance1Before = balance1();
        IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(
            amount0,
            amount1,
            data
        );
        if (balance1Before + uint256(amount1) < balance1())
            revert("UniswapV3Pool: UNDERFLOW");

        emit Swap(
            msg.sender,
            recipient,
            amount0,
            amount1,
            slot0.sqrtPriceX96,
            liquidity,
            slot0.tick
        );
    }

    function balance0() public view returns (uint256) {
        return IERC20(token0).balanceOf(address(this));
    }

    function balance1() public view returns (uint256) {
        return IERC20(token1).balanceOf(address(this));
    }
}
