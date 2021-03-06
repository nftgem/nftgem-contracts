// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./ERC20Constructorless.sol";

import "../interfaces/IERC20WrappedGem.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemFeeManager.sol";

import "./WrappedTokenLib.sol";

/**
 * @dev Wraps a gem (erc1155 'gem' type issued by an NFTGemPool) into erc1155
 */
contract ERC20WrappedGem is
    ERC20Constructorless,
    ERC1155Holder,
    IERC20WrappedGem,
    Initializable
{
    using WrappedTokenLib for WrappedTokenLib.WrappedTokenData;
    address internal _feeManager;

    WrappedTokenLib.WrappedTokenData internal tokenData;

    /**
     * @dev initialize contract state
     */
    function initialize(
        string memory name,
        string memory symbol,
        address gemPool,
        address gemToken,
        uint8 decimals,
        address feeManager
    ) external override initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _feeManager = feeManager;
        tokenData.erc1155token = gemToken;
        tokenData.erc20token = address(this);
        tokenData.tokenPool = gemPool;
        tokenData.index = 0;
        tokenData.rate = 1;
        tokenData.tokenType = INFTGemMultiToken.TokenType.GEM;
    }

    /**
     * @dev get fee to wrap tokens
     */
    function getWrapFee(uint256 totalQuantity)
        internal
        view
        returns (uint256 fd)
    {
        uint256 thisWrapFeeHash = uint256(
            keccak256(abi.encodePacked("wrap_gem", address(this)))
        );
        fd = INFTGemFeeManager(_feeManager).fee(thisWrapFeeHash);
        if (fd == 0) {
            thisWrapFeeHash = uint256(keccak256(abi.encodePacked("wrap_gem")));
            fd = INFTGemFeeManager(_feeManager).fee(thisWrapFeeHash);
        }
        return fd != 0 ? totalQuantity / fd : 0;
    }

    /**
     * @dev wrap gems to erc20
     */
    function wrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");
        require(
            WrappedTokenLib.getPoolTypeBalance(
                tokenData.erc1155token,
                tokenData.tokenPool,
                tokenData.tokenType,
                msg.sender
            ) >= quantity,
            "INSUFFICIENT_QUANTITY"
        );
        uint256 tq = quantity * (tokenData.rate * 10**decimals());

        uint256 fee = getWrapFee(tq);
        uint256 userQty = tq - fee;

        tokenData.transferPoolTypesFrom(msg.sender, address(this), quantity);
        _mint(msg.sender, userQty);
        _mint(_feeManager, fee);

        tokenData.wrappedBalance = tokenData.wrappedBalance + quantity;

        emit Wrap(msg.sender, quantity);
    }

    /**
     * @dev unwrap wrapped gems
     */
    function unwrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");
        require(
            balanceOf(msg.sender) * (10**decimals()) >= quantity,
            "INSUFFICIENT_QUANTITY"
        );

        tokenData.transferPoolTypesFrom(address(this), msg.sender, quantity);
        _burn(msg.sender, quantity * (10**decimals()));
        tokenData.wrappedBalance = tokenData.wrappedBalance - (quantity);

        emit Unwrap(msg.sender, quantity);
    }

    /**
     * @dev get reserves held in wrapper
     */
    function getReserves() external view override returns (uint256) {
        return tokenData.wrappedBalance;
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
