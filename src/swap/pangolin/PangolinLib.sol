// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "@pangolindex/exchange-contracts/contracts/pangolin-periphery/interfaces/IPangolinRouter.sol";
import "@pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinFactory.sol";
import "@pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinPair.sol";

/**
 * @dev Uniswap helpers
 */
library PangolinLib {

    address public constant PANGOLIN_ROUTER_ADDRESS = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
    address public constant FUJI_PANGOLIN_ROUTER_ADDRESS = 0xE4A575550C2b460d2307b82dCd7aFe84AD1484dd;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function avaxQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 avalanche,
            uint256 tokenReserve,
            uint256 avaxReserve
        )
    {
        IPangolinRouter uniswapRouter = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS );
        address _factory = uniswapRouter.factory();
        address _WAVAX = uniswapRouter.WAVAX();
        address _pair = IPangolinFactory(_factory).getPair(token, _WAVAX);
        (tokenReserve, avaxReserve, ) = IPangolinPair(_pair).getReserves();
        avalanche = quote(tokenAmount, tokenReserve, avaxReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS ).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function WAVAX() external pure returns (address wavax) {
        wavax = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS ).WAVAX();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IPangolinRouter uniswapRouter = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS );
        address _factory = uniswapRouter.factory();
        address _WAVAX = uniswapRouter.WAVAX();
        address _pair = IPangolinFactory(_factory).getPair(token, _WAVAX);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs wavax
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IPangolinFactory(_factory).getPair(
                tokenA,
                tokenB
            );
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IPangolinPair(pair).getReserves();
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        _factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"40231f6b438bce0797c9ada29b718a87ea0a5cea3fe9a771abdd76bd41a3e545" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for avalanche to the given token
     */
    function getPathForAVAXoToken(address token) external pure returns (address[] memory) {
        IPangolinRouter uniswapRouter = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS );
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WAVAX();
        return path;
    }

    /**
     * @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    /**
     * @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}
