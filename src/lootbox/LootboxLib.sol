// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ILootbox.sol";
import "../interfaces/IRandomFarm.sol";
import "../interfaces/ILootboxData.sol";
import "../interfaces/IControllable.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../access/Controllable.sol";
import "./TokenSeller.sol";

library LootboxLib {
    event LootboxCreated(
        address indexed creator,
        uint256 indexed hash,
        address indexed contractAddress,
        ILootbox.Lootbox data
    );

    event LootboxMigrated(
        address indexed migrator,
        uint256 indexed hash,
        address indexed oldContractAddress,
        address newContractAddress,
        ILootbox.Lootbox data
    );

    event LootboxOpened(
        address indexed opener,
        uint256 indexed hash,
        ILootbox.Lootbox openedLootbox,
        ILootbox.Loot[] receivedLoot
    );

    event LootAdded(
        address indexed adder,
        uint256 indexed hash,
        ILootbox.Lootbox addedLootbox,
        ILootbox.Loot addedLoot
    );

    event LootboxTokensMinted(
        address indexed minter,
        uint256 indexed hash,
        ILootbox.Lootbox mintedLootbox,
        uint256 mintedAmount
    );

    event LootMinted(
        address indexed minter,
        uint256 indexed hash,
        ILootbox.Lootbox mintedLootbox,
        ILootbox.Loot mintedLoot
    );

    /// @dev Sets the lootbox data. The lootbox contract can either initialise a new
    // lootbox struct or it can load and update an existing lootbox struct.
    function initialize(
        address contractAddress,
        address lootboxData,
        ITokenSeller.TokenSellerInfo memory tokenSellerInfo,
        ILootbox.Lootbox memory lootboxInit
    )
        external
        returns (
            ILootboxData _lootboxData,
            bool _isNew,
            ILootbox.Lootbox memory _lootbox,
            ITokenSeller.TokenSellerInfo memory tokenSellerInfo_
        )
    {
        require(
            IControllable(lootboxData).isController(address(this)) == true,
            "Lootbox data must be controlled by this lootbox"
        );
        tokenSellerInfo_ = tokenSellerInfo;
        _lootboxData = ILootboxData(lootboxData);
        _isNew = lootboxInit.lootboxHash == 0;
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
            _lootbox.lootboxHash = uint256(
                keccak256(abi.encodePacked(lootboxInit.symbol))
            );
            _lootbox.initialized = true;
        }
        _lootbox.contractAddress = contractAddress;
        tokenSellerInfo_.tokenHash = _lootbox.lootboxHash;
        // _lootboxData.setTokenSeller(contractAddress, tokenSellerInfo);
        if (_isNew) {
            _lootboxData.addLootbox(_lootbox);
        } else {
            // load the lootbox struct
            _lootbox = _lootboxData.getLootboxByHash(lootboxInit.lootboxHash);
            _lootbox.contractAddress = contractAddress;
            _lootboxData.setLootbox(_lootbox);
            require(
                _lootbox.owner == msg.sender,
                "Lootbox must be owned by the caller to uppgrade contract"
            );
        }
    }

    function openLootbox(
        ILootbox.Lootbox memory _lootbox,
        ILootbox.Loot[] memory _loot
    ) external returns (ILootbox.Loot[] memory _lootOut) {
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
        _lootOut = new ILootbox.Loot[](lootCount);

        // now we need some randomness to determine which loot items we win
        // we use a pseudo-random deterministic sieve to determine the number
        // and type of tokens minted

        uint256[] memory _lootRoll = new uint256[](lootCount);
        for (uint8 i = 0; i < lootCount; i++) {
            _lootRoll[i] = IRandomFarmer(_lootbox.randomFarmer).getRandomNumber(
                0,
                _lootbox.probabilitiesSum
            );
        }

        // mint the loot items
        for (uint256 i = 0; i < lootCount; i++) {
            // generate a loot item given a random seed
            (uint8 winIndex, uint256 winRoll) = _generateLoot(
                _loot,
                _lootRoll[i],
                _lootbox.probabilitiesSum
            );

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

    function mintLoot(
        ILootbox.Lootbox memory _lootbox,
        ILootbox.Loot[] memory _allLoot,
        uint8 index,
        uint256 amount
    ) external returns (ILootbox.Loot memory) {
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

    function _generateLoot(
        ILootbox.Loot[] memory _loot,
        uint256 dice,
        uint256 _probabilitiesSum
    ) internal pure returns (uint8 winnerIndex, uint256 winnerRoll) {
        // validate the dice roll is in the proper range
        require(
            dice < _probabilitiesSum,
            "Dice roll must be less than total probability"
        );
        uint256 floor = 0;
        // get all the loot there is to award

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

    function recalculateProbabilities(address lootboxData, uint256 _lootboxHash)
        public
        returns (ILootbox.Loot[] memory _allLootOut)
    {
        uint256 floor = 0;
        // iterate through the loot items
        ILootbox.Loot[] memory _allLoot = ILootboxData(lootboxData).allLoot(
            _lootboxHash
        );
        for (uint256 i = 0; i < _allLoot.length; i++) {
            // set the probability index to the floor
            _allLoot[i].probabilityIndex = floor + _allLoot[i].probability;
            floor += _allLoot[i].probability;
            ILootboxData(lootboxData).setLoot(_lootboxHash, i, _allLoot[i]);
        }
        _allLootOut = _allLoot;
    }
}
