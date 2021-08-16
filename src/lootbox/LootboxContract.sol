// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ILootbox.sol";
import "../interfaces/ILootboxData.sol";
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

contract LootboxContract is ILootbox, Controllable {
    ILootboxData private _lootboxData;

    constructor(
        address dataContract,
        address multitokenContract,
        uint8 dataVersion
    ) {
        // TODO: check to see if passed in data contract is a controller and revert if not
    }

    function openLootbox(uint256 lootHash) external override returns (Loot[]) {}

    function loot() external view override returns (Loot[]) {}

    function addLoot(Loot _loot) external override returns (uint256) {}

    function setLoot(uint256 index, Loot _loot) external override {}

    function getLoot(uint256 index) external override returns (Loot) {}

    function delLoot(uint256 index) external override returns (Loot) {

    function widthdrawFees(address receiver) external override {}
}
