// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../access/Controllable.sol";

import "../data/GenericDataSource.sol";

import "../interfaces/IERC1155TokenBridgeData.sol";

import "../interfaces/IERC1155TokenBridge.sol";

contract ERC1155TokenBridgeData is IERC1155TokenBridgeData, GenericDatasource {
    // validator list and map
    IERC1155TokenBridge.Validator[] internal validatorList;
    mapping(address => IERC1155TokenBridge.Validator) internal validatorMap;

    // rending request list and map
    IERC1155TokenBridge.NetworkTransferRequest[] internal pendingRequestList;
    mapping(uint256 => IERC1155TokenBridge.NetworkTransferRequest)
        internal pendingRequestMap;

    // registered token list and map
    address[] internal registeredTokenList;
    mapping(address => address) internal registeredTokenMap;

    modifier onlyAllowedToken(address _token) {
        require(
            registeredTokenMap[_token] != _token,
            "Token is not registered"
        );
        _;
    }

    // @dev ERC1155TokenBridgeData constructor
    constructor() {
        _addController(msg.sender);
    }

    // @dev get the fee manager address
    function getFeeManager() external view override returns (address) {
        return this.getAddr("feeManager");
    }

    // @dev set the fee manager address
    function setFeeManager(address feeManagerAddress)
        external
        override
        onlyController
    {
        require(
            msg.sender != address(0),
            "msg.sender cannot be the zero address"
        );
        this.setAddr("feeManager", feeManagerAddress);
    }

    /// validator data

    // @dev get the validator list
    function validators()
        external
        view
        override
        returns (IERC1155TokenBridge.Validator[] memory)
    {
        return validatorList;
    }

    // @dev add a validator to the validator list
    function addValidator(IERC1155TokenBridge.Validator memory validator)
        external
        override
        onlyController
        returns (uint256)
    {
        // check if validator is already in the list
        require(
            address(validator.validatorAddress) == address(0),
            "validator already exists"
        );
        // register the validator in map
        validatorMap[validator.validatorAddress] = validator;
        // and also in list
        validatorList.push(validator);
    }

    // @dev update validator in the validator list
    function setValidator(IERC1155TokenBridge.Validator memory validator)
        external
        override
        onlyController
        returns (uint256)
    {
        require(
            validator.validatorAddress != address(0),
            "validator address cannot be zero"
        );
        require(
            validatorMap[validator.validatorAddress].validatorAddress ==
                validator.validatorAddress,
            "Invalid validator state"
        );
        validatorMap[validator.validatorAddress] = validator;
    }

    // @dev get a validator given a validator hash
    function getValidator(address validatorAddress)
        external
        override
        returns (IERC1155TokenBridge.Validator memory validator)
    {
        validator = validatorMap[validatorAddress];
    }

    // request data

    // @dev get the pending request list
    function pendingRequests()
        external
        view
        override
        returns (IERC1155TokenBridge.NetworkTransferRequest[] memory)
    {
        return pendingRequestList;
    }

    // @dev add a pending request to the pending request list
    function addRequest(
        IERC1155TokenBridge.NetworkTransferRequest memory request
    ) external override onlyController returns (uint256) {
        require(request.id != 0, "request id cannot be zero");
        require(
            pendingRequestMap[request.id].id == 0,
            "request already exists"
        );
        pendingRequestMap[request.id] = request;
        pendingRequestList.push(request);
    }

    // @dev update a pending request in the pending request list
    function setRequest(
        IERC1155TokenBridge.NetworkTransferRequest memory request
    ) external override onlyController returns (uint256) {
        require(request.id != 0, "request id cannot be zero");
        require(
            pendingRequestMap[request.id].id == request.id,
            "Invalid request state"
        );
        pendingRequestMap[request.id] = request;
        // TODO find and update the request in the pending request list
    }

    // @dev get a pending request given a pending request hash
    function getRequest(uint256 requestHash)
        external
        view
        override
        returns (IERC1155TokenBridge.NetworkTransferRequest memory request)
    {
        request = pendingRequestMap[requestHash];
    }

    // @dev delete a pending request given a pending request hash
    function delRequest(uint256 requestHash)
        external
        override
        onlyController
        returns (bool)
    {
        require(
            pendingRequestMap[requestHash].id == requestHash,
            "Invalid request state"
        );
        pendingRequestMap[requestHash].id = 0;
        pendingRequestMap[requestHash].networkId = 0;
        pendingRequestMap[requestHash].from = address(0);
        pendingRequestMap[requestHash].to = address(0);
        // TODO: do not allow deleting the request if it's pending
        // TODO: return the validator bond to the operator
    }

    // registered tokens

    // @dev get the registered token list
    function registeredTokens()
        external
        view
        override
        returns (address[] memory)
    {
        return registeredTokenList;
    }

    // @dev register a token to be used by the bridge
    function registerToken(address token)
        external
        view
        override
        onlyController
        returns (uint256)
    {
        require(token != address(0), "token address must not be 0");
        require(
            registeredTokenMap[token] == address(0),
            "request already exists"
        );
        registeredTokenMap[token] == token;
    }

    // @dev unregister a token from the bridge
    function unregisterToken(address token) external override returns (bool) {
        require(token != address(0), "token address must not be 0");
        require(
            registeredTokenMap[token] != address(0),
            "token not registered"
        );
        registeredTokenMap[token] = address(0);
    }
}
