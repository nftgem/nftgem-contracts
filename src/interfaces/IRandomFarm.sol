// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IRandomFarmer {
    function getRandomBytes(uint8 amount) external returns (bytes32[] memory);

    function getRandomUints(uint8 amount) external returns (uint256[] memory);

    function getRandomNumber(uint256 min, uint256 max)
        external
        returns (uint256);
}

interface IRandomFarm is IRandomFarmer {
    function initialize(uint256 seed) external;

    function addRandomness(uint256 randomness) external;
}
