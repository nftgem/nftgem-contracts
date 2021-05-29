// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./PangolinLib.sol";
import "../../interfaces/ISwapQueryHelper.sol";
import "../../access/Controllable.sol";

/**
 * @dev Uniswap helpers
 */
contract PangolinQueryHelper is ISwapQueryHelper, Controllable {
    address private _routerAddress;

    address public constant PANGOLIN_ROUTER_ADDRESS = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
    address public constant FUJI_PANGOLIN_ROUTER_ADDRESS = 0xE4A575550C2b460d2307b82dCd7aFe84AD1484dd;

    constructor() {
        _routerAddress = PANGOLIN_ROUTER_ADDRESS;
    }

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
        return PangolinLib.avaxQuote(token, tokenAmount);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = PangolinLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = PangolinLib.WAVAX();
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return PangolinLib.hasPool(token);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = PangolinLib.factory();
        pair = PangolinLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(address pair) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = PangolinLib.getReserves(pair);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return PangolinLib.getPathForAVAXoToken(token);
    }

    /**
     * @dev set factory
     */
    function setFactory(address) external override {}
}
