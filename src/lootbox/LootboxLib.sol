// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ILootbox.sol";

library LootboxLib {
    struct Lootbox {
        ILootbox.Lootbox lootbox;
    }

    function openLootbox(Lootbox calldata self, uint256 lootHash)
        external
        returns (Loot[])
    {}

    function allLoot(Lootbox calldata self) external view returns (Loot[]) {}

    function addLoot(Lootbox calldata self, Loot _loot)
        external
        returns (uint256)
    {}

    function setLoot(
        Lootbox calldata self,
        uint256 index,
        Loot _loot
    ) external {}

    function getLoot(Lootbox calldata self, uint256 index)
        external
        returns (Loot)
    {}

    function delLoot(Lootbox calldata self, uint256 index)
        external
        returns (Loot)
    {}

    function eidthdrawFees(Lootbox calldata self, address receiver) external {}
}
