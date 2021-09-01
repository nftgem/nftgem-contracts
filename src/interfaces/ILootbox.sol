// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ITokenSeller.sol";

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

interface ILootbox {
    // the lootbox itself
    struct Lootbox {
        address owner; // the owner of the lootbox. they can do some admin things others cannot
        address contractAddress; // this is the address of the smart contract that implements lootbox
        address randomFarmer; // address of the random number generator used to generate the random numbers
        address multitoken; // address of the multitoken contract that mints the tokens
        uint256 lootboxHash; // identifier and lootbox token hash for the lootbox
        string symbol; // the symbol of the lootbox
        string name; // the name of the lootbox
        string description; // the description of the lootbox
        uint8 minLootPerOpen; // the minimum number of loot items that can be issued per open
        uint8 maxLootPerOpen; // the maximum number of loot items that can be issued per open
        uint256 maxOpens; // maximum number of times the lootbox can be opened
        // these are all values set by the system - not configurable by the user
        uint256 openCount;
        uint256 totalLootGenerated;
        uint256 probabilitiesSum;
        bool initialized;
    }

    // loot items
    struct Loot {
        uint256 lootHash;
        address owner;
        address multitoken;
        string symbol;
        string name;
        uint256 probability;
        uint256 probabilityIndex;
        uint256 probabilityRoll;
        uint256 maxMint;
        uint256 minted;
    }

    event LootboxCreated(
        address indexed creator,
        uint256 indexed hash,
        address indexed contractAddress,
        Lootbox data
    );

    event LootboxMigrated(
        address indexed migrator,
        uint256 indexed hash,
        address indexed oldContractAddress,
        address newContractAddress,
        Lootbox data
    );

    event LootboxOpened(
        address indexed opener,
        uint256 indexed hash,
        Lootbox openedLootbox,
        Loot[] receivedLoot
    );

    event LootAdded(
        address indexed adder,
        uint256 indexed hash,
        Lootbox addedLootbox,
        Loot addedLoot
    );

    event LootboxTokensMinted(
        address indexed minter,
        uint256 indexed hash,
        Lootbox mintedLootbox,
        uint256 mintedAmount
    );

    event LootMinted(
        address indexed minter,
        uint256 indexed hash,
        Lootbox mintedLootbox,
        Loot mintedLoot
    );

    function initialize(
        address lootboxData,
        ITokenSeller.TokenSellerInfo memory tokenSellerInfo,
        ILootbox.Lootbox memory lootboxInit
    ) external;

    function mintLootboxTokens(uint256 amount) external;

    function mintLoot(uint8 index, uint256 amount)
        external
        returns (Loot memory);

    function openLootbox() external returns (Loot[] memory);

    function allLoot() external view returns (Loot[] memory);

    function addLoot(Loot memory _loot) external returns (uint256);

    function getLoot(uint256 index) external view returns (Loot memory);

    // TODO: add a allItemsLength()
}
