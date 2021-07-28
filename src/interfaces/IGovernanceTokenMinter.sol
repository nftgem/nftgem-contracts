// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGovernanceTokenMinter {
    function bulkMint(
        address token,
        address[] memory recipients,
        uint256[] memory gquantities
    ) external;
}
