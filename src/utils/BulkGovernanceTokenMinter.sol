// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/IGovernanceTokenMinter.sol";
import "../interfaces/IGovernanceMintable.sol";

/**
 * @dev Collection of utility functions that mint tokens
 */
contract BulkGovernanceTokenMinter is IGovernanceTokenMinter, Controllable {
    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev Mint one token hash type to multiple accounts with multiple quantities
     */
    function bulkMint(
        address multitoken,
        address[] memory recipients,
        uint256[] memory quantities
    ) external override onlyController {
        for (uint256 i = 0; i < recipients.length; i++) {
            IGovernanceMintable(multitoken).mint(recipients[i], quantities[i]);
        }
    }
}
