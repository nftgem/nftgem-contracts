// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ITokenPoolQuerier {
    function getOwnedTokens(address gemPool, address multitoken, address account) external view returns (uint256[] memory claims, uint256[] memory gems);
}
