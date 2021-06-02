// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../access/Controllable.sol";
import "../interfaces/INFTGemWrapperFeeManager.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20.sol";

contract NFTGemWrapperFeeManager is Controllable, INFTGemWrapperFeeManager {
    address private operator;

    uint256 private constant FEE_DIVISOR = 2000;

    mapping(address => uint256) private feeDivisors;

    /**
     * @dev constructor
     */
    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev receive funds
     */
    receive() external payable {
        //
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function feeDivisor(address token) external view override returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? FEE_DIVISOR : divisor;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFeeDivisor(address token, uint256 _feeDivisor)
        external
        override
        onlyController
        returns (uint256 oldDivisor)
    {
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
        emit FeeDivisorChanged(operator, token, oldDivisor, _feeDivisor);
    }

    /**
     * @dev get the ETH balance of this fee manager
     */
    function ethBalanceOf() external view override returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev get the erc20 token balance of this fee manager
     */
    function balanceOfERC20(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev get the erc1155 token balance of this fee manager
     */
    function balanceOfERC1155(address token, uint256 id) external view override returns (uint256) {
        return IERC1155(token).balanceOf(address(this), id);
    }

    /**
     * @dev transfer ETH from this contract to the to given recipient
     */
    function transferEth(address payable recipient, uint256 amount) external override onlyController {
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");
        recipient.transfer(amount);
    }

    /**
     * @dev transfer erc20 tokens from this contract to the to given recipient
     */
    function transferERC20Token(
        address token,
        address recipient,
        uint256 amount
    ) external override onlyController {
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");
        IERC20(token).transfer(recipient, amount);
    }

    /**
     * @dev transfer erc1155 tokens from this contract to another contract
     */
    function transferERC1155Token(
        address token,
        uint256 id,
        address recipient,
        uint256 amount
    ) external override onlyController {
        require(IERC1155(token).balanceOf(address(this), id) >= amount, "INSUFFICIENT_BALANCE");
        IERC1155(token).safeTransferFrom(address(this), recipient, id, amount, "");
    }
}
