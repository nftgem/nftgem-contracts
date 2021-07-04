// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20WrappedERC1155 {
    function wrap(uint256 quantity) external;

    function unwrap(uint256 quantity) external;

    function getReserves() external returns (uint256);

    function getTokenAddress() external returns (address);

    function getTokenId() external returns (uint256);

    event Wrap(address indexed account, uint256 quantity);
    event Unwrap(address indexed account, uint256 quantity);

    function initialize(
        string memory,
        string memory,
        address,
        address,
        uint8,
        address
    ) external;
}
