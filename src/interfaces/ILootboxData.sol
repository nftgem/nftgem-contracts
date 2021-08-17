// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ILootbox.sol";

interface ILootboxData {
    function getLootbox(uint256 lootbox)
        external
        view
        returns (ILootbox.Lootbox memory);

    function setLootbox(uint256 lootbox, ILootbox.Lootbox memory lootboxData)
        external;

    function allLootboxes() external view returns (ILootbox.Lootbox[] memory);

    function getLoot(uint256 lootbox, uint256 index)
        external
        view
        returns (ILootbox.Loot memory);

    function addLoot(uint256 lootbox, ILootbox.Loot memory lootboxData)
        external
        returns (uint256);

    function setLoot(
        uint256 lootbox,
        uint256 index,
        ILootbox.Loot memory lootboxData
    ) external;

    function allLoot(uint256 lootbox)
        external
        view
        returns (ILootbox.Loot[] memory);

    function delLoot(uint256 lootbox, uint256 index)
        external
        returns (ILootbox.Loot memory);
}
