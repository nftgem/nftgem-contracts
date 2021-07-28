// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBulkTokenSender {
    function bulkSend(
        address tokenAddress,
        address[] memory recipients,
        uint256[] memory gquantities
    ) external;
}
