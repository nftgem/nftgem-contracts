// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ITokenSeller.sol";
import "../access/Controllable.sol";
import "@openzeppelin/contracts/contracts/proxy/utilities/Initializable.sol";

contract TokenSeller is ITokenSeller, Controllable, Initializable {

    TokenSellerInfo private info;
    mapping(address => uint256) private totalBought;

    constructor() {
        _addController(msg.sender);
    }

    function initialize(TokenSellerInfo _info) external initializer {
        require(info.multitoken != address(0), "Multitoken is not set");
        require(info.tokenHash != 0, "token hash is not set");
        require(info.buyPrice != 0, "buy price is not set");
        info = _info;
        info.initialized = true;
    }

    function isInitialized() external view returns (bool) {
        return info.initialized;
    }

    function getInfo() external view returns (TokenSellerInfo) {
        return info;
    }

    function setInfo(TokenSellerInfo _info) external onlyController {
        info.buyPrice = _info.buyPrice;
        info.maxQuantity = _info.maxQuantity;
        info.buyPriceIncreaseRate = _info.buyPriceIncreaseRate;
        info.buyPriceIncreaseRateType = _info.buyPriceIncreaseRateType;
        info.maxBuyAmount = _info.maxBuyAmount;
        info.maxBuyTotal = _info.maxBuyTotal;
    }

    function _request(
        address _recipient,
        uint256 _token,
        uint256 _amount
    ) internal returns (uint256) {
        // mint the target token directly into the user's account
        INFTGemMultiTokem(info.multitoken).mint(_recipient, _token, _amount);
        // set the token data - it's not a claim or gem and it was minted here
        INFTGemMultiTokem(info.multitoken).setTokenData(
            _token,
            INFTGemMultiTokem.TokenType.GOVERNANCE,
            address(this)
        );
    }

    function _increaseBuyPrice() internal view returns (uint256) {
        switch(info.buyPriceIncreaseRateType) {
            case BuyPriceIncreaseRateType.NONE:
                return info.buyPrice;
            case BuyPriceIncreaseRateType.FIXED:
                return info.buyPrice + info.buyPriceIncreaseRate;
            case BuyPriceIncreaseRateType.EXPONENTIAL:
                return info.buyPrice + (info.buyPrice/info.buyPriceIncreaseRate);
            case BuyPriceIncreaseRateType.INVERSELOG:
                return info.buyPrice + (info.buyPriceIncreaseRate/info.buyPrice);
            default:
                return info.buyPrice;
        }
    }

    /// @dev Buy tokens from the token seller.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @param tokenHash The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were bought.
    function buy(uint256 _amount, uint256 tokenHash)
        external
        returns (uint256)
    {
        require(
            info.totalBought < info.maxQuantity,
            "The maximum amount of tokens has been bought."
        );
        require(
            msg.value >= info.buyPrice * _amount,
            "Insufficient base currency"
        );
        require(
            _amount <= info.maxBuyAmount,
            "Amount exceeds maximum buy amount"
        );
        require(
            _amount <=
                info.maxBuyTotal -
                    IERC1155(info.multitoken).balanceOf(msg.sender, tokenHash),
            "Amount exceeds maximum buy total"
        );
        // request (mint) the tokens
        _request(msg.sender, tokenHash, _amount);
        // increase total bought
        info.totalBought += _amount;
        // emit a message about the purchase
        emit Sold(msg.sender, tokenHash, info.buyPrice, _amount);
        // increase the purchase price if it's not fixed
        info.buyPrice = _increaseBuyPrice();
        // return the amount of tokens that were bought
        return _amount;
    }

    /// @dev Request tokens from the token provider.
    /// @param _recipient The address of the token receiver.
    /// @param _token The token hash being requested.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were requested.
    function request(
        address _recipient,
        uint256 _token,
        uint256 _amount
    ) external onlyController returns (uint256) {
        require(
            info.totalBought < info.maxQuantity,
            "The maximum amount of tokens has been bought."
        );
        totalBought_ += _amount;
        Requested(_recipient, _token, _amount);
        return _amount;
    }

    /// @
}
