// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC1155TokenBridge.sol";

interface IERC1155TokenBridgeData {
    // fee manager address
    function getFeeManager() external view returns (address);

    function setFeeManager(address feeManagerAddress) external;

    // validator data

    // list of validator data
    function validators()
        external
        returns (IERC1155TokenBridge.Validator[] memory);

    // add validator
    function addValidator(IERC1155TokenBridge.Validator memory validator)
        external
        returns (uint256);

    // set validator data
    function setValidator(IERC1155TokenBridge.Validator memory validator)
        external
        returns (uint256);

    // get validator data
    function getValidator(uint256 validatorHash)
        external
        returns (IERC1155TokenBridge.Validator memory);

    // request data

    // a list of (not started, pending) requests
    function pendingRequests()
        external
        returns (IERC1155TokenBridge.NetworkTransferRequest[] memory requests);

    function addRequest(
        // add a new request
        IERC1155TokenBridge.NetworkTransferRequest memory request
    ) external returns (uint256);

    // set request data
    function setRequest(
        IERC1155TokenBridge.NetworkTransferRequest memory request
    ) external returns (uint256);

    // get request by hash
    function getRequest(uint256 requestHash)
        external
        returns (IERC1155TokenBridge.NetworkTransferRequest memory request);

    // delete the request data to free up space
    function delRequest(uint256 requestHash) external returns (bool);
}
