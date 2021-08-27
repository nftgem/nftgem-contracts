// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ITokenSeller.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemFeeManager.sol";
import "../interfaces/ILootboxData.sol";
import "../access/Controllable.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract TokenSeller is ITokenSeller, Controllable, Initializable {
    ILootboxData internal _tokenSellerData;
    ITokenSeller.TokenSellerInfo internal _tokenSeller;

    constructor() {
        _addController(msg.sender);
    }

    /// @dev contract must be initilized for modified method to be called
    modifier initialized() virtual {
        require(
            _tokenSeller.multitoken != address(0) &&
                _tokenSeller.initialized == true,
            "Token seller is not initialized"
        );
        _;
    }

    /// @dev Sets the lootbox data. The lootbox contract can either initialise a new
    // lootbox struct or it can load and update an existing lootbox struct.
    function initialize(
        address tokenSellerData,
        ITokenSeller.TokenSellerInfo memory tokenSellerInit
    ) external override initializer {
        require(
            IControllable(tokenSellerData).isController(address(this)) == true,
            "Token seller data must be controlled by this token seller"
        );
        _tokenSellerData = ILootboxData(tokenSellerData);
        if (tokenSellerInit.contractAddress == address(0)) {
            require(
                tokenSellerInit.multitoken != address(0),
                "Multitoken address must be set"
            );
            require(tokenSellerInit.tokenHash != 0, "token hash must be set");
            require(tokenSellerInit.buyPrice != 0, "Price must be set");
            _tokenSeller = tokenSellerInit;
            _tokenSeller.contractAddress = address(this);
            _tokenSeller.initialized = true;
            _tokenSellerData.addTokenSeller(address(this), _tokenSeller);
            emit TokenSellerCreated(msg.sender, _tokenSeller);
        } else {
            // load the lootbox struct
            _tokenSeller = _tokenSellerData.getTokenSeller(address(this));
            _tokenSeller.contractAddress = address(this);
            _tokenSellerData.setTokenSeller(address(this), _tokenSeller);
            require(
                _tokenSeller.owner == msg.sender,
                "Lootbox must be owned by the caller to uppgrade contract"
            );
            emit TokenSellerMigrated(
                msg.sender,
                address(this),
                _tokenSeller.contractAddress,
                address(this),
                _tokenSeller
            );
        }
    }

    function isInitialized() external view override returns (bool) {
        return _tokenSeller.initialized;
    }

    function getInfo() external view override returns (TokenSellerInfo memory) {
        return _tokenSeller;
    }

    function setInfo(TokenSellerInfo memory _info)
        external
        override
        onlyController
    {
        _tokenSeller.buyPrice = _info.buyPrice;
        _tokenSeller.buyPriceIncreaseRateType = _info.buyPriceIncreaseRateType;
        _tokenSeller.buyPriceIncreaseRate = _info.buyPriceIncreaseRate;
        _tokenSeller.maxQuantity = _info.maxQuantity;
        _tokenSeller.maxBuyAmount = _info.maxBuyAmount;
        _tokenSeller.maxTotalBuyAmount = _info.maxTotalBuyAmount;
        _tokenSeller.saleStartTime = _info.saleStartTime;
        _tokenSeller.saleEndTime = _info.saleEndTime;
        _tokenSeller.open = _info.open;
        _tokenSeller.maxTotalBuyAmount = _info.maxTotalBuyAmount;
        _tokenSellerData.setTokenSeller(address(this), _tokenSeller);
    }

    function _request(
        address _recipient,
        uint256 _token,
        uint256 _amount
    ) internal returns (uint256) {
        // mint the target token directly into the user's account
        INFTGemMultiToken(_tokenSeller.multitoken).mint(
            _recipient,
            _token,
            _amount
        );
        // set the token data - it's not a claim or gem and it was minted here
        INFTGemMultiToken(_tokenSeller.multitoken).setTokenData(
            _token,
            INFTGemMultiToken.TokenType.GOVERNANCE,
            address(this)
        );
        return _amount;
    }

    /// @dev Buy tokens from the token seller.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were bought.
    function buy(uint256 _amount) external payable override returns (uint256) {
        require(_tokenSeller.open == true, "The token seller is closed");
        require(
            _tokenSeller.totalPurchased < _tokenSeller.maxQuantity,
            "The maximum amount of tokens has been bought."
        );
        require(
            msg.value >= _tokenSeller.buyPrice * _amount,
            "Insufficient base currency"
        );
        require(
            _amount <= _tokenSeller.maxBuyAmount,
            "Amount exceeds maximum buy amount"
        );
        require(
            _amount <=
                _tokenSeller.maxTotalBuyAmount -
                    IERC1155(_tokenSeller.multitoken).balanceOf(
                        msg.sender,
                        _tokenSeller.tokenHash
                    ),
            "Amount exceeds maximum buy total"
        );
        require(
            block.timestamp >= _tokenSeller.saleStartTime ||
                _tokenSeller.saleStartTime == 0,
            "The sale has not started yet"
        );
        require(
            block.timestamp <= _tokenSeller.saleEndTime ||
                _tokenSeller.saleEndTime == 0,
            "The sale has ended"
        );
        // request (mint) the tokens
        _request(msg.sender, _tokenSeller.tokenHash, _amount);
        // increase total bought
        _tokenSeller.totalPurchased += _amount;
        // emit a message about the purchase
        emit Sold(
            address(this),
            msg.sender,
            _tokenSeller.tokenHash,
            _tokenSeller.buyPrice,
            _amount
        );
        // increase the purchase price if it's not fixed
        _tokenSeller.buyPrice = _tokenSellerData.increaseBuyPrice(address(this));
        _tokenSellerData.setTokenSeller(address(this), _tokenSeller);
        // return the amount of tokens that were bought
        return _amount;
    }

    /// @dev Request tokens from the token provider.
    /// @param _recipient The address of the token receiver.
    /// @param _amount The amount of erc1155 tokens to buy.
    /// @return The amount of erc1155 tokens that were requested.
    function request(address _recipient, uint256 _amount)
        external
        override
        onlyController
        returns (uint256)
    {
        require(
            _tokenSeller.totalPurchased < _tokenSeller.maxQuantity,
            "The maximum amount of tokens has been bought."
        );
        return _request(_recipient, _tokenSeller.tokenHash, _amount);
    }

    function migrate_TokenSeller(address migrateTo, bool bDestroy) external initialized onlyController {
        IControllable(address(_tokenSellerData)).addController(migrateTo);
        ITokenSeller(migrateTo).initialize(
            address(_tokenSellerData),
            _tokenSeller
        );
         if(bDestroy == true) {
             selfdestruct(payable(migrateTo));
         }
    }

    function receivePayout(address payable _recipient) external override {
        require(
            this.isController(msg.sender) || msg.sender == _tokenSeller.owner,
            "Only the token seller can receive payouts"
        );
        uint256 balance = payable(address(this)).balance;
        if (balance == 0) {
            return;
        }
        address feeManager = _tokenSellerData.getFeeManager();
        require(
            feeManager != address(this),
            "The token seller has no fee manager"
        );
        uint256 fee = INFTGemFeeManager(feeManager).fee(
            uint256(keccak256(abi.encodePacked("lootbox")))
        );
        _recipient = _recipient != address(0)
            ? _recipient
            : payable(msg.sender);
        fee = fee != 0 ? fee : 333;
        uint256 feeAmount = balance / fee;
        uint256 userPortion = balance - feeAmount;
        require(payable(_recipient).send(userPortion), "Failed to send");
        require(
            payable(feeManager).send(feeAmount),
            "Failed to send to fee manager"
        );
        emit FundsCollected(_recipient, userPortion);
    }
}
