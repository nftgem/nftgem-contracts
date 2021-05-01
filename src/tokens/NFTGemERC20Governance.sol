// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";
import "./ERC20WrappedERC1155.sol";

contract NFTGemWrappedERC20Governance is ERC20WrappedERC1155 {
    using SafeMath for uint256;

    constructor(
        string memory name,
        string memory symbol,
        address erc1155Token
    ) ERC20WrappedERC1155(name, symbol, 8, erc1155Token, 0, 1) {}
}
