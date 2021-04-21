
// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../../interfaces/ISwapQueryHelper.sol";
import "../../libs/SafeMath.sol";

/**
 * @dev Mock helper for local network
 */
contract MockQueryHelper is ISwapQueryHelper {
    using SafeMath for uint256;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address, uint256 tokenAmount)
        external
        pure
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return ( tokenAmount.div(10), tokenAmount.mul(200), tokenAmount.mul(20));
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = address(0);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = address(99);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address, address) external pure override returns (address pair) {
        pair = address(0);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address
    ) external pure override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = (0, 0);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address,
        address
    ) external pure override returns (address pair) {
        pair = address(0);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address) external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address) external pure override returns (address[] memory) {
        address[] memory _mock;
        return _mock;
    }

}
