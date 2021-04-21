// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IControllable {
    function initialize(uint256) external;

    function initialize2(uint256, uint256) external;
}
