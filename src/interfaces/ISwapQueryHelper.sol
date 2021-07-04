// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapQueryHelper {
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function factory() external view returns (address);

    function COIN() external pure returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function hasPool(address token) external view returns (bool);

    function getReserves(address pair) external view returns (uint256, uint256);

    function getPathForCoinToToken(address token)
        external
        pure
        returns (address[] memory);

    function setFactory(address f) external;
}
