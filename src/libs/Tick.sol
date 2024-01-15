pragma solidity ^0.8.23;

library Tick {
    struct Info {
        bool initialized;
        uint128 liquidity;
    }

    function update(mapping(int24 => Info) storage self, int24 tick, uint128 liquidityDelta) internal {
        Info storage info = self[tick];
        uint128 liquidityBefore = info.liquidity;
        uint128 liquidityAfter =  liquidityBefore + liquidityDelta;

        if (liquidityBefore == 0 && liquidityAfter > 0) {
            info.initialized = true;
        }

        info.liquidity = liquidityAfter;
    }
}