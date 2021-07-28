// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface INFTGemFeeManager {
    event FeeChanged(
        address indexed operator,
        uint256 indexed feeHash,
        uint256 value
    );

    function fee(uint256 feeTypeHash) external view returns (uint256);

    function setFee(uint256 feeTypeHash, uint256 _fee) external;

    function balanceOf(address token) external view returns (uint256);

    function transferEth(address payable recipient, uint256 amount) external;

    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external;
}
