// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./ILootbox.sol";

/**
 * @dev Interface for a Bitgem lootbox factory
 */
interface ILootboxFactory {
    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event LootboxCreated(
        uint256 id,
        address contractAddress,
        ILootbox.Lootbox data
    );

    event LootboxMigrated(
        uint256 id,
        address contractAddress,
        ILootbox.Lootbox data
    );

    function initialize(address) external;

    function getLootbox(uint256 _symbolHash)
        external
        view
        returns (ILootbox.Lootbox memory);

    function lootboxes() external view returns (ILootbox.Lootbox[] memory _all);

    function allLootboxes(uint256 idx) external view returns (ILootbox.Lootbox memory _lootbox);

    function allLootboxesLength() external view returns (uint256);

    function createLootbox(address owner, ILootbox.Lootbox memory _lootbox, ITokenSeller.TokenSellerInfo memory _tokenSellerInfo)
        external
        returns (ILootbox.Lootbox memory);
}
