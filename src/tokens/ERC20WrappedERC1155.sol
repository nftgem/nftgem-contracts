// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";
import "./ERC20.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20.sol";
import "./ERC1155Holder.sol";

contract ERC20WrappedERC1155 is ERC20, ERC1155Holder {
    using SafeMath for uint256;

    address private token;
    uint256 private index;
    uint256 private rate;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address erc1155Token,
        uint256 tokenIndex,
        uint256 exchangeRate
    ) ERC20(name, symbol) {
        token = erc1155Token;
        index = tokenIndex;
        rate = exchangeRate;
        _setupDecimals(decimals);
    }

    function wrap(uint256 quantity) external {

        require(quantity != 0, "ZERO_QUANTITY");
        require(IERC1155(token).balanceOf(msg.sender, index) >= quantity, "INSUFFICIENT_ERC1155_BALANCE");

        IERC1155(token).safeTransferFrom(msg.sender, address(this), index, quantity, "");
        _mint(msg.sender, quantity.mul(rate));

    }

    function unwrap(uint256 quantity) external {

        require(quantity != 0, "ZERO_QUANTITY");
        require(balanceOf(msg.sender) >= quantity.mul(rate), "INSUFFICIENT_ERC20_BALANCE");

        _burn(msg.sender, quantity.mul(rate));
        IERC1155(token).safeTransferFrom(address(this), msg.sender, index, quantity, "");

    }
}
