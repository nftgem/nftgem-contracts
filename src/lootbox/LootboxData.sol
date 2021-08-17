// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../data/GenericDataSource.sol";

import "../interfaces/ILootboxData.sol";

import "../interfaces/INFTGemMultiToken.sol";

import "../interfaces/INFTComplexGemPoolData.sol";

import "../interfaces/ILootbox.sol";

contract LootboxData is ILootboxData, GenericDatasource {
    ILootbox.Lootbox[] private _allLootboxes;

    mapping(uint256 => ILootbox.Lootbox) private _lootboxes;
    mapping(uint256 => ILootbox.Loot[]) private _loot;

    mapping(uint256 => ILootbox.Loot) private _lootHashes;
    ILootbox.Loot[] private _mintedLoot;

    constructor() {
        _addController(msg.sender);
    }

    function getLootbox(uint256 lootbox)
        external
        view
        override
        onlyController
        returns (ILootbox.Lootbox memory)
    {
        return _lootboxes[lootbox];
    }

    function setLootbox(uint256 lootbox, ILootbox.Lootbox memory lootboxData)
        external
        override
        onlyController
    {
        if (_lootboxes[lootbox].owner == address(0)) {
            _allLootboxes.push(lootboxData);
        }
        _lootboxes[lootbox] = lootboxData;
    }

    function allLootboxes()
        external
        view
        override
        onlyController
        returns (ILootbox.Lootbox[] memory)
    {
        return _allLootboxes;
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
}
