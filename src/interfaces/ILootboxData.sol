import "ILootbox.sol";

interface ILootboxData {
    function getLootbox(address lootbox) external returns (Lootbox);

    function setLootbox(
        address lootbox,
        uint256 index,
        ILootbox lootboxData
    ) external;

    function allLootboxes() external view returns (Lootbox[]);

    function getLoot(address lootbox) external returns (Loot);

    function addLoot(address lootbox, Loot lootboxData) external;

    function setLoot(
        address lootbox,
        uint256 index,
        Loot lootboxData
    ) external;

    function allLoot(address lootbox) external view returns (Loot[]);

    function delLoot(address lootbox, uint256 index)
        external
        view
        returns (bool);
}
