// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./PancakeSwapLib.sol";
import "../../interfaces/ISwapQueryHelper.sol";

/**
 * @dev Uniswap helpers
 */
contract PancakeSwapQueryHelper is ISwapQueryHelper {
    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
        return PancakeSwapLib.coinQuote(token, tokenAmount);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = PancakeSwapLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = PancakeSwapLib.COIN();
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return PancakeSwapLib.hasPool(token);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB)
        external
        view
        override
        returns (address pair)
    {
        address _factory = PancakeSwapLib.factory();
        pair = PancakeSwapLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(address pair)
        external
        view
        override
        returns (uint256 reserveA, uint256 reserveB)
    {
        (reserveA, reserveB) = PancakeSwapLib.getReserves(pair);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token)
        external
        pure
        override
        returns (address[] memory)
    {
        return PancakeSwapLib.getPathForCoinToToken(token);
    }

    /**
     * @dev set factory
     */
    function setFactory(address) external override {}
}
