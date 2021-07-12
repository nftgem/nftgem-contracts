// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/IBulkTokenSender.sol";

/**
 * @dev Collection of utility functions that mint tokens
 */
contract BulkTokenSender is IBulkTokenSender, Controllable {
    constructor() {
        _addController(msg.sender);
    }

    function bulkSend(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory gquantities
    ) external override onlyController {
        for (uint256 i = 0; i < recipients.length; i++) {
            IERC20(tokenAddress).transferFrom(
                address(this),
                recipients[i],
                gquantities[i]
            );
        }
    }
}
