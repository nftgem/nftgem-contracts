
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./FuniswapLib.sol";
import "../../interfaces/ISwapQueryHelper.sol";

/**
 * @dev Funiswap helpers
 */
contract FuniswapQueryHelper is ISwapQueryHelper {

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
       return FuniswapLib.ethQuote(token, tokenAmount);
    }

    /**
     * @dev does a Funiswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = FuniswapLib.factory();
    }

    /**
     * @dev does a Funiswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = FuniswapLib.WETH();
    }


    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = FuniswapLib.factory();
        pair = FuniswapLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = FuniswapLib.getReserves(pair);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) external pure override returns (address pair) {
        address _factory = FuniswapLib.factory();
        pair = FuniswapLib.pairFor(_factory, tokenA, tokenB);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return FuniswapLib.hasPool(token);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return FuniswapLib.getPathForETHToToken(token);
    }

}
