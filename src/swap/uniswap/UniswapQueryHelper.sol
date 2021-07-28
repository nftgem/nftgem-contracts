// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./UniswapLib.sol";
import "../../interfaces/ISwapQueryHelper.sol";
import "../../access/Controllable.sol";

/**
 * @dev Uniswap helpers
 */
contract UniswapQueryHelper is ISwapQueryHelper, Controllable {
    address private customFactory;

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
        return UniswapLib.ethQuote(token, tokenAmount);
    }

    function __factory() internal view returns (address fac) {
        fac = customFactory != address(0)
            ? customFactory
            : UniswapLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external view override returns (address fac) {
        fac = __factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = UniswapLib.WETH();
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
        pair = UniswapLib.getPair(__factory(), tokenA, tokenB);
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
        (reserveA, reserveB) = UniswapLib.getReserves(pair);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return UniswapLib.hasPool(token);
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
        return UniswapLib.getPathForETHToToken(token);
    }

    /**
     * @dev set factory
     */
    function setFactory(address f) external override onlyController {
        customFactory = f;
    }
}
