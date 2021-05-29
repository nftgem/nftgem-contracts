// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/IBulkTokenMinter.sol";


contract BulkTokenMinter is IBulkTokenMinter {
    function bulkMintToken(address multitoken, address[] memory recipients, uint256 tokenHash, uint256[] memory quantities) external override {
        for(uint256 i = 0; i < recipients.length; i++) {
            INFTGemMultiToken(multitoken).mint(recipients[i], tokenHash, quantities[i]);
        }
    }
    function bulkMintGovFuel(address multitoken, address[] memory recipients, uint256[] memory gquantities, uint256[] memory fquantities) external override {
        for(uint256 i = 0; i < recipients.length; i++) {
            INFTGemMultiToken(multitoken).mint(recipients[i], 0, gquantities[i]);
            INFTGemMultiToken(multitoken).mint(recipients[i], 1, fquantities[i]);
        }
    }
}
