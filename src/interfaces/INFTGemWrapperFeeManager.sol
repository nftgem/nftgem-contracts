// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface INFTGemWrapperFeeManager {
    event DefaultFeeDivisorChanged(address indexed operator, uint256 oldValue, uint256 value);
    event FeeDivisorChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);
    event ETHReceived(address indexed manager, address sender, uint256 value);

    function feeDivisor(address token) external view returns (uint256);

    function setFeeDivisor(address token, uint256 _feeDivisor) external returns (uint256);

    function ethBalanceOf() external view returns (uint256);

    function balanceOfERC20(address token) external view returns (uint256);

    function balanceOfERC1155(address token, uint256 id) external view returns (uint256);

    function transferEth(address payable recipient, uint256 amount) external;

    function transferERC20Token(
        address token,
        address recipient,
        uint256 amount
    ) external;

    function transferERC1155Token(
        address token,
        uint256 id,
        address recipient,
        uint256 amount
    ) external;
}
