// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @dev A token seller is a contract that can sell tokens to a token buyer.
/// The token buyer can buy tokens from the seller by paying a certain amount
/// of base currency to receive a certain amount of erc1155 tokens. the number
/// of tokens that can be bought is limited by the seller - the seller can
/// specify the maximum number of tokens that can be bought per transaction
/// and the maximum number of tokens that can be bought in total for a given
/// address. The seller can also specify the price of erc1155 tokens and how
/// that price increases per successful transaction. the token seller assumes
/// supply of the erc1155 is unlimited and features a request method

interface ITokenSeller {

    enum BuyPriceIncreaseRateType {
        NONE,
        FIXED,
        PERCENTAGE
    };

    struct TokenSellerInfo {
        address multitoken;
        uint256 tokenHash;
        uint256 buyPrice;
        uint256 maxQuantity;
        uint256 maxBuyAmount;
        uint256 maxTotalBuyAmount;
        BuyPriceIncreaseRateType buyPriceIncreaseRateType;
        uint256 buyPriceIncreaseRate;
        bool initialized;
    }

    event Sold(address indexed contract, address indexed buyer, uint256 indexed tokenHash, uint256 price, uint256 amount);

    event Requested(
        address indexed contract,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 amount
    );

    event Funded(
        address indexed contract,
        uint256 indexed tokenId,
        uint256 amount
    );

    function initialize(TokenSellerInfo _info) external;

    function isInitialized() external view returns (bool);

    function getInfo() external view returns (TokenSellerInfo);

    function setInfo(TokenSellerInfo _info) external;

    /// @dev Buy tokens from the token seller.
    /// @param _buyer The address of the token buyer.
    /// @param _value The amount of base currency to pay to buy tokens.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @param _data Additional data to pass to the token buyer.
    /// @return The amount of erc1155 tokens that were bought.
    function buy(uint256 _amount) external returns (uint256);

    /// @dev Buy tokens from the token seller.
    /// @param _hash The address of the token buyer.
    /// @param _amount The amount of base currency to pay to buy tokens.
    /// @return The amount of erc1155 tokens that were bought.
    function fund(uint256 _hash, uint256 _amount) external returns (uint256);

    /// @dev Request tokens from the token provider.
    /// @param _recipient The address of the token receiver.
    /// @param _token The token hash being requested.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were requested.
    function request(
        address _recipient,
        uint256 _token,
        uint256 _amount
    ) external returns (uint256);

}
