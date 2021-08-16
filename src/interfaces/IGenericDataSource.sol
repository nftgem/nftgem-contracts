interface IGenericDatasource {
    function getStr(string memory key) external returns (string memory);

    function setStr(string memory key, string memory value)
        external
        returns (string memory);

    function getInt(string memory key) external returns (uint256);

    function setInt(string memory key, uint256 value) external;

    function getBool(string memory key) external returns (bool);

    function setBool(string memory key, bool value) external;

    function getBytes(string memory key) external returns (bytes memory);

    function setBytes(string memory key, bytes memory value) external;

    function getAddr(string memory key) external returns (address);

    function setAddr(string memory key, address value) external;
}
