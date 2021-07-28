// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBulkTokenMinter {
    function bulkMintGov(
        address multitoken,
        address[] memory recipients,
        uint256[] memory gquantities
    ) external;

    function bulkMintToken(
        address multitoken,
        address[] memory recipients,
        uint256 tokenHash,
        uint256[] memory quantities
    ) external;
}
