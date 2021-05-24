// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

interface IUnigem20Callee {
    function Unigem20Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
