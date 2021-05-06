// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";
import "./ERC20.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20WrappedERC1155.sol";
import "../interfaces/IERC20.sol";
import "./ERC1155Holder.sol";
import "./WrappedTokenLib.sol";

contract ERC20WrappedERC1155 is ERC20, ERC1155Holder, IERC20WrappedERC1155 {
    using SafeMath for uint256;
    using WrappedTokenLib for WrappedTokenLib.WrappedTokenData;

    WrappedTokenLib.WrappedTokenData internal tokenData;

    /**
     * @dev constructor sets up token parameters. this token wraps bitgem governance tokens.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address erc1155Token,
        uint256 tokenIndex,
        uint256 exchangeRate
    ) ERC20(name, symbol) {
        tokenData.erc1155token = erc1155Token;
        tokenData.tokenPool = address(0);
        tokenData.index = tokenIndex;
        tokenData.tokenType = 0;
        tokenData.rate = exchangeRate;
        _setupDecimals(decimals);
    }

    /**
     * @dev initialize is a stub because this class is deployed by us with constructor params
     */
    function initialize(
        string memory,
        string memory,
        address,
        address,
        uint8
    ) external override {
        tokenData.erc20token = address(this);
    }

    function _wrap(uint256 quantity) internal {
        require(quantity != 0, "ZERO_QUANTITY");
        require(
            IERC1155(tokenData.erc1155token).balanceOf(msg.sender, tokenData.index) >= quantity,
            "INSUFFICIENT_ERC1155_BALANCE"
        );
        IERC1155(tokenData.erc1155token).safeTransferFrom(msg.sender, address(this), tokenData.index, quantity, "");
        _mint(msg.sender, quantity.mul(tokenData.rate * 10**decimals()));
    }

    /**
     * @dev wrap a quantity of erc1155 governance to erc20
     */
    function wrap(uint256 quantity) external virtual override {
        _wrap(quantity);
    }

    /**
     * @dev unwrap a quantity of wrapped erc20 governance to erc1155
     */
    function _unwrap(uint256 quantity) internal {
        require(quantity != 0, "ZERO_QUANTITY");
        require(
            IERC1155(tokenData.erc1155token).balanceOf(address(this), tokenData.index) >= quantity,
            "INSUFFICIENT_RESERVES"
        );
        require(balanceOf(msg.sender) >= quantity.mul(tokenData.rate * 10**decimals()), "INSUFFICIENT_ERC20_BALANCE");
        _burn(msg.sender, quantity.mul(tokenData.rate * 10**decimals()));
        IERC1155(tokenData.erc1155token).safeTransferFrom(address(this), msg.sender, tokenData.index, quantity, "");
    }

    /**
     * @dev unwrap a quantity of wrapped erc20 governance to erc1155
     */
    function unwrap(uint256 quantity) external virtual override {
        _unwrap(quantity);
    }

    /**
     * @dev get reserves held in wrapper
     */
    function getReserves() external view override returns (uint256) {
        return IERC1155(tokenData.erc1155token).balanceOf(address(this), tokenData.index);
    }

    /**
     * @dev get the token address this wrapper is bound to
     */
    function getTokenAddress() external view override returns (address) {
        return tokenData.erc1155token;
    }

    /**
     * @dev get the token id this wrapper is bound to
     */
    function getTokenId() external view override returns (uint256) {
        return tokenData.index;
    }
}
