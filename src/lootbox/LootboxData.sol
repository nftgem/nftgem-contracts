// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../data/GenericDataSource.sol";

import "../interfaces/ILootboxData.sol";

import "../interfaces/ITokenSeller.sol";

import "../interfaces/INFTGemMultiToken.sol";

import "../interfaces/INFTComplexGemPoolData.sol";

import "../interfaces/ILootbox.sol";

contract LootboxData is ILootboxData, GenericDatasource {
    // all track lootboxes - as an array, by hash, and by symbol hash
    ILootbox.Lootbox[] private _allLootboxes;
    mapping(uint256 => ILootbox.Lootbox) private _lootboxes;
    mapping(address => ILootbox.Lootbox) private _lootboxesByAddress;

    // tracks loot for each lootbox
    mapping(uint256 => ILootbox.Loot[]) private _loot;

    // tracks token sale data
    ITokenSeller.TokenSellerInfo[] private _allTokenSellers;
    mapping(address => ITokenSeller.TokenSellerInfo) private _tokenSellers;

    constructor() {
        _addController(msg.sender);
    }

    function addLootbox(ILootbox.Lootbox memory _lootbox)
        external
        override
        returns (uint256 lootbox)
    {
        require(bytes(_lootbox.symbol).length != 0, "symbol must be set");
        if(_lootbox.lootboxHash == 0) {
            _lootbox.lootboxHash = uint256(keccak256(abi.encodePacked(_lootbox.symbol)));
        }
        if(_lootbox.contractAddress == address(0)) {
            _lootbox.contractAddress = msg.sender;
        }
        _allLootboxes.push(_lootbox);
        _lootboxes[_lootbox.lootboxHash] = _lootbox;
        _lootboxesByAddress[_lootbox.contractAddress] = _lootbox;
        return _allLootboxes.length - 1;
    }

    function getLootboxByAddress(address lootbox)
        external
        view
        override
        onlyController
        returns (ILootbox.Lootbox memory)
    {
        return _lootboxesByAddress[lootbox];
    }

    function getLootboxByHash(uint256 lootbox)
        external
        view
        override
        onlyController
        returns (ILootbox.Lootbox memory)
    {
        return _lootboxes[lootbox];
    }

    function lootboxes()
        external
        view
        override
        onlyController
        returns (ILootbox.Lootbox[] memory)
    {
        return _allLootboxes;
    }

    function allLootboxes(uint256 index)
        external
        view
        override
        onlyController
        returns (ILootbox.Lootbox memory)
    {
        return _allLootboxes[index];
    }

    function allLootboxesLength()
        external
        view
        override
        onlyController
        returns (uint256)
    {
        return _allLootboxes.length;
    }

    function setLootbox(
        ILootbox.Lootbox memory lootboxData
    ) external override onlyController {
        require(_lootboxes[lootboxData.lootboxHash].contractAddress != address(0)
        && _lootboxes[lootboxData.lootboxHash].contractAddress == lootboxData.contractAddress, "lootbox must be initialized");
        // TODO: upddate this so it only sets the updateable fields
        _lootboxes[lootboxData.lootboxHash] = lootboxData;
    }

    function getLoot(uint256 lootbox, uint256 index)
        external
        view
        override
        onlyController
        returns (ILootbox.Loot memory)
    {
        return _loot[lootbox][index];
    }

    function addLoot(uint256 lootbox, ILootbox.Loot memory lootboxData)
        external
        override
        onlyController
        returns (uint256)
    {
        require(_lootboxes[lootbox].owner != address(0), "Lootbox is not set"); // require a valid lootbox
        _loot[lootbox].push(lootboxData);
        return _loot[lootbox].length;
    }

    function setLoot(
        uint256 lootbox,
        uint256 index,
        ILootbox.Loot memory lootboxData
    ) external override onlyController {
        require(index < _loot[lootbox].length, "Index out of bounds");
        _loot[lootbox][index] = lootboxData;
    }

    function allLoot(uint256 lootbox)
        external
        view
        override
        onlyController
        returns (ILootbox.Loot[] memory)
    {
        return _loot[lootbox];
    }

    function delLoot(uint256 lootbox, uint256 index)
        external
        override
        onlyController
        returns (ILootbox.Loot memory lootboxData)
    {
        require(
            index >= 0 && index < _loot[lootbox].length,
            "Index out of bounds"
        );
        uint256 lastEl = _loot[lootbox].length - 1;
        lootboxData = _loot[lootbox][index];
        if (lastEl > index) {
            _loot[lootbox][index] = _loot[lootbox][lastEl];
        }
        _loot[lootbox].pop();
    }

    function addTokenSeller(
        address tokenSeller,
        ITokenSeller.TokenSellerInfo memory tokenSellerInfo
    ) external override onlyController returns (uint256 tokenSellerIndex) {
        require(
            _tokenSellers[tokenSeller].multitoken == address(0),
            "Token seller already exists"
        );
        _tokenSellers[tokenSeller] = tokenSellerInfo;
        return _allTokenSellers.length;
    }

    function getTokenSeller(address tokenSeller)
        external
        view
        override
        onlyController
        returns (ITokenSeller.TokenSellerInfo memory)
    {
        return _tokenSellers[tokenSeller];
    }

    function setTokenSeller(
        address tokenSellerAddress,
        ITokenSeller.TokenSellerInfo memory tokenSellerData
    ) external override onlyController {
        require(msg.sender == tokenSellerAddress, "Token seller is not set");
        _tokenSellers[tokenSellerAddress] = tokenSellerData;
    }

    function tokenSellers()
        external
        view
        override
        onlyController
        returns (ITokenSeller.TokenSellerInfo[] memory)
    {
        return _allTokenSellers;
    }

    function allTokenSellers(uint256 index)
        external
        view
        override
        onlyController
        returns (ITokenSeller.TokenSellerInfo memory)
    {
        return _allTokenSellers[index];
    }

    function allTokenSellersLength()
        external
        view
        override
        onlyController
        returns (uint256)
    {
        return _allTokenSellers.length;
    }

    function getFeeManager() external view override returns (address) {
        return this.getAddr("feeManagerAddress");
    }

    function setFeeManager(address feeManagerAddress) external override {
        this.setAddr("feeManagerAddress", feeManagerAddress);
    }

    function increaseBuyPrice(address tokenSeller) external view override returns (uint256) {
        ITokenSeller.TokenSellerInfo memory _tokenSeller = _tokenSellers[tokenSeller];
        if (
            _tokenSeller.buyPriceIncreaseRateType ==
            ITokenSeller.BuyPriceIncreaseRateType.NONE
        ) {
            return _tokenSeller.buyPrice;
        } else if (
            _tokenSeller.buyPriceIncreaseRateType ==
            ITokenSeller.BuyPriceIncreaseRateType.FIXED
        ) {
            return _tokenSeller.buyPrice + _tokenSeller.buyPriceIncreaseRate;
        } else if (
            _tokenSeller.buyPriceIncreaseRateType ==
            ITokenSeller.BuyPriceIncreaseRateType.EXPONENTIAL
        ) {
            return
                _tokenSeller.buyPrice +
                (_tokenSeller.buyPrice / _tokenSeller.buyPriceIncreaseRate);
        } else if (
            _tokenSeller.buyPriceIncreaseRateType ==
            ITokenSeller.BuyPriceIncreaseRateType.INVERSELOG
        ) {
            return
                _tokenSeller.buyPrice +
                (_tokenSeller.buyPriceIncreaseRate / _tokenSeller.buyPrice);
        }
        return _tokenSeller.buyPrice;
    }
}
