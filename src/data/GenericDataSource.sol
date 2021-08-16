// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IGenericDataSource.sol";
import "../access/Controllable.sol";

/// this contract provides a generic data source for other smart contracts.
/// data can be set and retrieved by the owner of the contract. The basic datattypes
/// are supported: string, bytes, uint, bool, and address. Data is set and retrieved
/// through the 'setXXX' and 'getXXX' methods. This contract exists to enable a
/// modular design pattern that enables easy upgrades of business logic without
/// changing the smart contract.
contract GenericDatasource is IGenericDatasource, Controllable {
    mapping(string => string) internal stringData;
    mapping(string => bytes32) internal bytesData;
    mapping(string => uint256) internal uintData;
    mapping(string => bool) internal boolData;
    mapping(string => address) internal addressData;

    /// @dev contract constructor
    constructor() {
        _addController(msg.sender);
    }

    /// @dev set a string value
    /// @param key the key of the string value
    /// @return the value if the value was set, falsey otherwise
    function getStr(string key)
        external
        override
        onlyController
        returns (string)
    {
        return stringData[key];
    }

    /// @dev set a string value
    /// @param key the key of the string value
    /// @param value the value to set
    /// @return string the old data the the new data replaced
    function setStr(string memory key, string memory value) external override onlyController returns{string memory oldData} {
        oldData = stringData[key];
        stringData[key] = value;
    }

    function getInt(string key)
        external
        override
        onlyController
        returns (uint256 _data)
    {
        _data = uintData[key];
    }

    function setInt(string key, uint256 value)
        external
        override
        onlyController
    {
        uintData[key] = value;
    }

    function getBool(string key)
        external
        override
        onlyController
        returns (bool _data)
    {
        _data = boolData[key];
    }

    function setBool(string key, bool bval) external override onlyController {
        boolData[key] = bval;
    }

    function getBytes(string key)
        external
        override
        onlyController
        returns (bytes)
    {
        return bytesData[key];
    }

    function setBytes(string key, bytes value)
        external
        override
        onlyController
    {
        bytesData[key] = value;
    }

    function getAddr(string key)
        external
        override
        onlyController
        returns (address)
    {
        return addressData[key];
    }

    function setAddr(string key, address value)
        external
        override
        onlyController
    {
        addressData[key] = value;
    }
}
