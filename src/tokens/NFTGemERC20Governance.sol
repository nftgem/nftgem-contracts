// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";
import "../interfaces/INFTGemFeeManager.sol";
import "./ERC20WrappedERC1155.sol";

/**
* @dev wraps governance (token id 0)
*/
contract NFTGemWrappedERC20Governance is ERC20WrappedERC1155 {
    using SafeMath for uint256;
    address internal _feeManager;

    /**
    * @dev create contract
    */
    constructor(
        string memory name,
        string memory symbol,
        address erc1155Token,
        address feeManager
    ) ERC20WrappedERC1155(name, symbol, 18, erc1155Token, 0, 1) {
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
        uint256 tq = quantity.mul(tokenData.rate * 10**decimals());
        uint256 fd = INFTGemFeeManager(_feeManager).feeDivisor(address(this));
        uint256 fee = fd != 0 ? tq.div(fd) : 0;
        uint256 userQty = tq.sub(fee);
        IERC1155(tokenData.erc1155token).safeTransferFrom(msg.sender, address(this), tokenData.index, quantity, "");
        _mint(msg.sender, userQty);
        _mint(_feeManager, fee);
    }

    /**
    * @dev unwrap tokens - transfer erc1155 to contract, mintt erc20
    */
    function unwrap(uint256 quantity) external override {
        _unwrap(quantity);
    }
}
