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
        EXPONENTIAL,
        INVERSELOG
    }

    struct TokenSellerInfo {
        address multitoken;
        address contractAddress;
        address owner;
        uint256 tokenHash;
        uint256 buyPrice;
        BuyPriceIncreaseRateType buyPriceIncreaseRateType;
        uint256 buyPriceIncreaseRate;
        uint256 maxQuantity;
        uint256 maxBuyAmount;
        uint256 maxTotalBuyAmount;
        uint256 saleStartTime;
        uint256 saleEndTime;
        bool initialized;
        bool open;
        uint256 totalPurchased;
    }

    event TokenSellerCreated(address indexed creator, TokenSellerInfo info);

    event Sold(
        address indexed contractAddress,
        address indexed buyer,
        uint256 indexed tokenHash,
        uint256 price,
        uint256 amount
    );

    event Requested(
        address indexed contractAddress,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 amount
    );

    event Funded(
        address indexed contractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    event FundsCollected(address indexed receiver, uint256 indexed amount);

    event TokenSellerMigrated(
        address indexed migrator,
        address indexed hash,
        address indexed oldContractAddress,
        address newContractAddress,
        TokenSellerInfo data
    );

    function initialize(address tokenSellerData, TokenSellerInfo memory _info)
        external;

    function isInitialized() external view returns (bool);

    function getInfo() external view returns (TokenSellerInfo memory);

    function setInfo(TokenSellerInfo memory _info) external;

    /// @dev Buy tokens from the token seller.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were bought.
    function buy(uint256 _amount) external payable returns (uint256);

    /// @dev Request tokens from the token provider.
    /// @param _recipient The address of the token receiver.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were requested.
    function request(address _recipient, uint256 _amount)
        external
        returns (uint256);

    function receivePayout(address payable _recipient) external;
}
