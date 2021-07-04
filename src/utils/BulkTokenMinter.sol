// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/IBulkTokenMinter.sol";

/**
 * @dev Collection of utility functions that mint tokens
 */
contract BulkTokenMinter is IBulkTokenMinter {
    /**
     * @dev Mint one token hash type to multiple accounts with multiple quantities
     */
    function bulkMintToken(
        address multitoken,
        address[] memory recipients,
        uint256 tokenHash,
        uint256[] memory quantities
    ) external override {
        for (uint256 i = 0; i < recipients.length; i++) {
            INFTGemMultiToken(multitoken).mint(
                recipients[i],
                tokenHash,
                quantities[i]
            );
        }
    }

    /**
     * @dev Mint governance to recipients
     */
    function bulkMintGov(
        address multitoken,
        address[] memory recipients,
        uint256[] memory gquantities
    ) external override {
        for (uint256 i = 0; i < recipients.length; i++) {
            INFTGemMultiToken(multitoken).mint(
                recipients[i],
                0,
                gquantities[i]
            );
        }
    }
}
