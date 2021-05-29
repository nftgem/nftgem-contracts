// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IBulkTokenMinter {
    function bulkMintGovFuel(address multitoken, address[] memory recipients, uint256[] memory gquantities, uint256[] memory fquantities) external;
    function bulkMintToken(address multitoken, address[] memory recipients, uint256 tokenHash, uint256[] memory quantities) external;
}
