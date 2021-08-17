// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IGenericDatasource {
    function getStr(string memory key) external view returns (string memory);

    function setStr(string memory key, string memory value)
        external
        returns (string memory);

    function getInt(string memory key) external view returns (uint256);

    function setInt(string memory key, uint256 value) external;

    function getBool(string memory key) external view returns (bool);

    function setBool(string memory key, bool value) external;

    function getBytes(string memory key) external view returns (bytes memory);

    function setBytes(string memory key, bytes memory value) external;

    function getAddr(string memory key) external view returns (address);

    function setAddr(string memory key, address value) external;
}
