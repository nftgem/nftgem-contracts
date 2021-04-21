// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol";
import "@pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol";

/**
 * @dev pancake helpers
 */
library PancakeSwapLib {

    address public constant PANCAKE_ROUTER_ADDRESS = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 coin,
            uint256 tokenReserve,
            uint256 coinReserve
        )
    {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS );
        address _factory = pancakeRouter.factory();
        address _COIN = pancakeRouter.WETH();
        address _pair = IPancakeFactory(_factory).getPair(token, _COIN);
        (tokenReserve, coinReserve, ) = IPancakePair(_pair).getReserves();
        coin = quote(tokenAmount, tokenReserve, coinReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS ).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure returns (address wavax) {
        wavax = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS ).WETH();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS );
        address _factory = pancakeRouter.factory();
        address _WAVAX = pancakeRouter.WETH();
        address _pair = IPancakeFactory(_factory).getPair(token, _WAVAX);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs wavax
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IPancakeFactory(_factory).getPair(
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
        (reserveA, reserveB, ) = IPancakePair(pair).getReserves();
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
                        hex"d0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for coin to the given token
     */
    function getPathForCoinToToken(address token) external pure returns (address[] memory) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS );
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = pancakeRouter.WETH();
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
