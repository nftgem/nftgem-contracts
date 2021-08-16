// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../data/GenericDatasource.sol";

import "../interface/ILootboxData.sol";

contract LootboxData is ILootboxData, GenericDatasource {
    Lootbox[] private _allLootboxes;
    mapping(address => Lootbox) private _lootboxes;
    mapping(address => Loot[]) private _loot;

    constructor() {
        _addController(msg.sender);
    }

    function getLootbox(address lootbox) external returns (Lootbox) {
        return lootboxes[lootbox];
    }

    function setLootbox(address lootbox, Lootbox lootboxData) external {
        if (bytes(lootboxes[lootbox]).length == 0) {
            _allLootboxes.push(lootboxData);
        }
        lootboxes[lootbox] = lootboxData;
    }

    function allLootboxes() external view returns (Lootbox[]) {
        return _allLootboxes;
    }

    function getLoot(address lootbox, uint256 index) external returns (Loot) {
        return _loot[lootbox][index];
    }

    function addLoot(address lootbox, Loot lootboxData) external {
        if (bytes(_loot[lootbox]).length == 0) {
            _loot[lootbox] = Array(lootboxData.index);
        }
    }

    function setLoot(
        address lootbox,
        uint256 index,
        Loot lootboxData
    ) external {
        _loot[lootbox][index] = lootboxData;
    }

    function allLoot(address lootbox) external view returns (Loot[]) {
        return _loot[lootbox];
    }

    function delLoot(address lootbox, uint256 index)
        external
        view
        returns (bool)
    {
        require(
            index >= 0 && index < _loot[lootbox].length,
            "Index out of bounds"
        );
        uint356 lastEl = _loot[lootbox].length - 1;
        if (lastEl > index) {
            _loot[lootbox][index] = _loot[lootbox][lastEl];
        }
        _loot[lootbox].pop();
    }
}
