// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/ILootbox.sol";
import "../interfaces/IRandomFarm.sol";
import "../interfaces/ILootboxData.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../access/Controllable.sol";
import "./TokenSeller.sol";
import "./LootboxLib.sol";

/// @dev A lootbox is a contract that works with an erc1155 to implement a game lootbox:
/// a lootbox is a contract that accepts a single quantity of some erc1155 tokenhash and
/// then based on a set of rules goverened by probability, mints one or more outgoing tokens
/// as it burns the incoming token. The rules are defined by the lootbox author and are
/// stored in the lootbox contract. A newly-created lootbox contract assigns controllership
/// to its creator, who can them add other controllers, and can set the rules for the lootbox.
/// Each lootbox is configured with some number of Loot items, each of which has deterministic
/// tokenhash. These loot items each have names, symbols, and a probability of being minted.
/// Users open the lootbox by providing the right gem to the lootbox contract, and then
/// the lootbox contract mints the right number of tokens for the user. This contract uses
/// a pseudo-random deterministic sieve to determine the number and type of tokens minted

contract LootboxContract is ILootbox, Controllable, Initializable, TokenSeller {
    ILootboxData internal _lootboxData;
    ILootbox.Lootbox internal _lootbox;

    constructor() {
        _addController(msg.sender);
    }

    /// @dev contract must be initilized for modified method to be called
    modifier initialized() override {
        require(
            _lootbox.lootboxHash != 0 && _lootbox.initialized == true,
            "Lootbox is not initialized"
        );
        _;
    }

    /// @dev Sets the lootbox data. The lootbox contract can either initialise a new
    // lootbox struct or it can load and update an existing lootbox struct.
    function initialize(
        address lootboxData,
        ITokenSeller.TokenSellerInfo memory tokenSellerInfo,
        ILootbox.Lootbox memory lootboxInit
    ) external override initializer {
        require(
            IControllable(lootboxData).isController(address(this)) == true,
            "Lootbox data must be controlled by this lootbox"
        );
        _lootboxData = ILootboxData(lootboxData);
        bool isNew = lootboxInit.lootboxHash == 0;
        _lootbox = LootboxLib.initialize(lootboxInit);
        _lootbox.contractAddress = address(this);
        tokenSellerInfo.tokenHash = _lootbox.lootboxHash;
        this.initialize(lootboxData, tokenSellerInfo);
        _lootboxData.setTokenSeller(address(this), tokenSellerInfo);
        if (isNew) {
            _lootboxData.addLootbox(_lootbox);
            emit LootboxCreated(
                msg.sender,
                _lootbox.lootboxHash,
                address(this),
                _lootbox
            );
        } else {
            // load the lootbox struct
            _lootbox = _lootboxData.getLootboxByHash(lootboxInit.lootboxHash);
            _lootbox.contractAddress = address(this);
            _lootboxData.setLootbox(_lootbox);
            require(
                _lootbox.owner == msg.sender,
                "Lootbox must be owned by the caller to uppgrade contract"
            );
            emit LootboxMigrated(
                msg.sender,
                _lootbox.lootboxHash,
                _lootbox.contractAddress,
                address(this),
                _lootbox
            );
        }
    }

    function openLootbox()
        external
        override
        initialized
        returns (Loot[] memory _lootOut)
    {
        Loot[] memory _allLoot = _lootboxData.allLoot(_lootbox.lootboxHash);
        return LootboxLib.openLootbox(_lootbox, _allLoot);
    }

    function mintLootboxTokens(uint256 amount)
        external
        override
        initialized
        onlyController
    {
        // mint the loot item to the owner
        INFTGemMultiToken(_lootbox.multitoken).mint(
            msg.sender,
            _lootbox.lootboxHash,
            amount
        );

        // generate an event reporting on the loot that was found
        emit LootboxTokensMinted(
            msg.sender,
            _lootbox.lootboxHash,
            _lootbox,
            amount
        );
    }

    function mintLoot(uint8 index, uint256 amount)
        external
        override
        initialized
        onlyController
        returns (Loot memory)
    {
        Loot[] memory _allLoot = _lootboxData.allLoot(_lootbox.lootboxHash);
        return LootboxLib.mintLoot(_lootbox, _allLoot, index, amount);
    }

    function allLoot()
        external
        view
        override
        initialized
        returns (Loot[] memory)
    {
        return _lootboxData.allLoot(_lootbox.lootboxHash);
    }

    function addLoot(Loot memory _loot)
        external
        override
        initialized
        onlyController
        returns (uint256 _result)
    {
        // basic sanity checks
        require(bytes(_loot.symbol).length > 0, "Symbol must be set");
        require(bytes(_loot.name).length > 0, "name must be set");
        require(_loot.probability > 0, "probability must be set");

        // populate field values the loot must have
        _loot.owner = _lootbox.owner;
        _loot.multitoken = _lootbox.multitoken;
        _loot.probabilityIndex = _lootbox.probabilitiesSum + _loot.probability;
        _lootbox.probabilitiesSum += _loot.probability;
        _lootboxData.setLootbox(_lootbox);
        _loot.lootHash = uint256(
            keccak256(abi.encodePacked(_lootbox.symbol, _loot.symbol))
        );

        // emit a message about it
        emit LootAdded(msg.sender, _lootbox.lootboxHash, _lootbox, _loot);

        // return the addeduint loot item index
        _result = _lootboxData.addLoot(_lootbox.lootboxHash, _loot);
    }

    function getLoot(uint256 index)
        external
        view
        override
        initialized
        returns (Loot memory)
    {
        return _lootboxData.getLoot(_lootbox.lootboxHash, index);
    }

    function withdrawFees(address receiver)
        external
        initialized
        onlyController
    {
        require(address(this).balance > 0, "Lootbox is empty");
        payable(receiver).transfer(address(this).balance);
    }

    function migrate_LootboxContract(address migrateTo)
        external
        initialized
        onlyController
    {
        this.migrate_TokenSeller(migrateTo, false);
        IControllable(address(_lootboxData)).addController(migrateTo);
        ILootbox(migrateTo).initialize(
            address(_lootboxData),
            _tokenSeller,
            _lootbox
        );
    }
}
