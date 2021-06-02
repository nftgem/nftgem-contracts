// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";
import "../interfaces/INFTGemWrapperFeeManager.sol";
import "./ERC20WrappedERC1155.sol";

/**
* @dev wraps fuel (token id 1155)
*/
contract NFTGemWrappedERC20Fuel is ERC20WrappedERC1155 {
    using SafeMath for uint256;
    address internal _feeManager;

    /**
    * @dev create the contract
    */
    constructor(
        string memory name,
        string memory symbol,
        address erc1155Token,
        address feeManager
    ) ERC20WrappedERC1155(name, symbol, 18, erc1155Token, 1, 1) {
        _feeManager = feeManager;
    }

    /**
    * @dev wrap tokens - transfer erc1155 to contract, mintt erc20
    */
    function wrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");
        require(
            IERC1155(tokenData.erc1155token).balanceOf(msg.sender, tokenData.index) >= quantity,
            "INSUFFICIENT_ERC1155_BALANCE"
        );
        uint256 fd = INFTGemWrapperFeeManager(_feeManager).feeDivisor(address(this));
        uint256 fee = fd != 0 ? quantity.div(fd) : 0;
        uint256 userQty = quantity.sub(fee);
        IERC1155(tokenData.erc1155token).safeTransferFrom(msg.sender, address(this), tokenData.index, quantity, "");
        _mint(msg.sender, userQty);
        _mint(_feeManager, fee);
    }

    /**
    * @dev unwrap tokens -  burn erc20 token, transfer erc1155 to account
    */
    function unwrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");
        require(
            IERC1155(tokenData.erc1155token).balanceOf(address(this), tokenData.index) >= quantity,
            "INSUFFICIENT_RESERVES"
        );
        require(balanceOf(msg.sender) >= quantity, "INSUFFICIENT_ERC20_BALANCE");
        _burn(msg.sender, quantity);
        IERC1155(tokenData.erc1155token).safeTransferFrom(address(this), msg.sender, tokenData.index, quantity, "");
    }
}
