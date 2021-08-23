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

/// @dev A lootbox is a contract that works with an erc1155 to implement a game lootbox:
/// a lootbox is a contract that accepts a single quantity of some erc1155 tokenhash and
/// then based on a set of rules goverened by probability, mints one or more outgoing tokens
/// as it burns the incoming token. The rules are defined by the lootbox author and are
/// stored in the lootbox contract. A newly-created lootbox contract assigns controllership
/// to its creator, who can them add other controllers, and can set the rules for the lootbox.
/// Each lootbox is configured with some number of Loot items, each of which has deterministic
/// tokenhash. These loot items each have names, symboles, and a probability of being minted.
/// Users open the lootbox by providing the right gem to the lootbox contract, and then
/// the lootbox contract mints the right number of tokens for the user. This contract uses
/// a pseudo-random deterministic sieve to determine the number and type of tokens minted

contract LootboxContract is ILootbox, Controllable, Initializable {
    ILootboxData internal _lootboxData;
    ILootbox.Lootbox internal _lootbox;

    constructor() {
        _addController(msg.sender);
    }

    /// @dev contract must be initilized for modified method to be called
    modifier initialized() {
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
        ILootbox.Lootbox memory lootboxInit
    ) external override initializer {
        require(
            IControllable(lootboxData).isController(address(this)) == true,
            "Lootbox data must be controlled by this lootbox"
        );
        _lootboxData = ILootboxData(lootboxData);
        if (lootboxInit.lootboxHash == 0) {
            require(
                lootboxInit.multitoken != address(0),
                "Multitoken address must be set"
            );
            require(bytes(lootboxInit.name).length != 0, "Name must be set");
            require(
                bytes(lootboxInit.symbol).length != 0,
                "Symbol must be set"
            );
            require(lootboxInit.minLootPerOpen != 0, "Min loot must be set");
            require(lootboxInit.maxLootPerOpen != 0, "Max loot must be set");
            // TODO: additional validity checks would not hurt here
            _lootbox = lootboxInit;
            _lootbox.owner = msg.sender;
            _lootbox.lootboxHash = uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        lootboxInit.multitoken,
                        lootboxInit.symbol,
                        lootboxInit.name,
                        block.timestamp
                    )
                )
            );
            _lootbox.initialized = true;
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
        // make sure that the caller has at least one lootbox token
        require(
            IERC1155(_lootbox.multitoken).balanceOf(
                msg.sender,
                _lootbox.lootboxHash
            ) > 0,
            "Insufficient lootbox token balance"
        );

        // no need to transfer the lootbox token anywhere, we can just burn it in place
        INFTGemMultiToken(_lootbox.multitoken).burn(
            msg.sender,
            _lootbox.lootboxHash,
            1
        );

        // first we need to determine the number of loot items to mint
        // if min == max, then we mint that exact number of items. Otherwise,
        // we use a random number between min and max to determine the number
        // of loot items to mint
        uint8 lootCount = _lootbox.minLootPerOpen;
        if (_lootbox.minLootPerOpen != _lootbox.maxLootPerOpen) {
            lootCount = uint8(
                IRandomFarmer(_lootbox.randomFarmer).getRandomNumber(
                    uint256(_lootbox.minLootPerOpen),
                    uint256(_lootbox.maxLootPerOpen)
                )
            );
        } else lootCount = _lootbox.minLootPerOpen;

        // now that we know how much we need to mint, we can create the
        // loot roll array that will hold our results and create some loot
        _lootOut = new Loot[](lootCount);

        // grab the array of loot items to disburse from
        Loot[] memory _loot = _lootboxData.allLoot(_lootbox.lootboxHash);

        // now we need some randomness to determine which loot items we win
        // we use a pseudo-random deterministic sieve to determine the number
        // and type of tokens minted
        uint256[] memory _lootRoll = IRandomFarmer(_lootbox.randomFarmer)
            .getRandomUints(lootCount);

        // mint the loot items
        for (uint256 i = 0; i < lootCount; i++) {
            // generate a loot item given a random seed
            (uint8 winIndex, uint256 winRoll) = _generateLoot(_lootRoll[i]);
            // assign the loot item to the loot array
            _lootOut[i] = _loot[winIndex];
            _lootOut[i].probabilityRoll = winRoll;
            // mint the loot item to the multitoken
            INFTGemMultiToken(_lootbox.multitoken).mint(
                msg.sender,
                _lootOut[i].lootHash,
                1
            );
        }

        /// generate an event reporting on the loot that was found
        emit LootboxOpened(
            msg.sender,
            _lootbox.lootboxHash,
            _lootbox,
            _lootOut
        );
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
        // require a valid loot index
        Loot[] memory _allLoot = _lootboxData.allLoot(_lootbox.lootboxHash);
        require(index < _allLoot.length, "Loot index out of bounds");
        // mint the loot item to the minter
        INFTGemMultiToken(_lootbox.multitoken).mint(
            msg.sender,
            _allLoot[index].lootHash,
            amount
        );
        // forced to use GOVERNANCE here as a token type because
        // someone decided to 'clean up' what they didn't understand.
        // there was a very good reason for this, that being that an
        // int type rather than an enum allows us to easily add new
        // token types. Noe I have to figure out how to handle this
        // in some other way. Thanks, Justin
        INFTGemMultiToken(_lootbox.multitoken).setTokenData(
            _allLoot[index].lootHash,
            INFTGemMultiToken.TokenType.GOVERNANCE,
            address(this)
        );

        // emit a message about it
        emit LootMinted(
            msg.sender,
            _lootbox.lootboxHash,
            _lootbox,
            _allLoot[index]
        );
        // return the loot item we minted
        return _allLoot[index];
    }

    function _generateLoot(uint256 dice)
        internal
        view
        returns (uint8 winnerIndex, uint256 winnerRoll)
    {
        // validate the dice roll is in the proper range
        require(
            dice < _lootbox.probabilitiesSum,
            "Dice roll must be less than total probability"
        );
        uint256 floor = 0;
        // get all the loot there is to award
        Loot[] memory _loot = _lootboxData.allLoot(_lootbox.lootboxHash);
        // iterate through the loot items
        for (uint256 i = 0; i < _loot.length; i++) {
            // if the dice roll is between the floor and the probability index
            // then this is the item we will award
            if (floor <= dice && dice < _loot[i].probabilityIndex) {
                winnerIndex = uint8(i);
                winnerRoll = dice;
                break;
            }
            // increment the floor to the next probability index
            floor = _loot[i].probabilityIndex;
        }
        return (winnerIndex, winnerRoll);
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
        returns (uint256)
    {
        // basic sanity checks
        require(bytes(_loot.symbol).length > 0, "Symbol must be set");
        require(bytes(_loot.name).length > 0, "name must be set");
        require(_loot.probability > 0, "probability must be set");

        // populate field values the loot must have
        _loot.multitoken = _lootbox.multitoken;
        _loot.probabilityIndex = _lootbox.probabilitiesSum + _loot.probability;
        _lootbox.probabilitiesSum += _loot.probability;
        _loot.lootHash = uint256(
            keccak256(abi.encodePacked(_lootbox.lootboxHash, _loot.symbol))
        );

        // emit a message about it
        emit LootAdded(msg.sender, _lootbox.lootboxHash, _lootbox, _loot);

        // return the added loot item index
        return _lootboxData.addLoot(_lootbox.lootboxHash, _loot);
    }

    function _recalculateProbabilities() internal {
        // get all the loot there is to award
        Loot[] memory _allLoot = _lootboxData.allLoot(_lootbox.lootboxHash);
        uint256 floor = 0;
        // iterate through the loot items
        for (uint256 i = 0; i < _allLoot.length; i++) {
            // set the probability index to the floor
            _allLoot[i].probabilityIndex = floor + _allLoot[i].probability;
            floor += _allLoot[i].probability;
            _lootboxData.setLoot(_lootbox.lootboxHash, i, _allLoot[i]);
        }
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

    function feeBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function migrate(address migrateTo) external initialized onlyController {
        IControllable(address(_lootboxData)).addController(migrateTo);
        ILootbox(migrateTo).initialize(address(_lootboxData), _lootbox);
        selfdestruct(payable(migrateTo));
    }
}
