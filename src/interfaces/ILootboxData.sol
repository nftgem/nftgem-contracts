// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./ILootbox.sol";
import "./ITokenSeller.sol";

interface ILootboxData {
    function getFeeManager() external view returns (address);

    function setFeeManager(address feeManagerAddress) external;

    function addLootbox(ILootbox.Lootbox memory)
        external
        returns (uint256 lootbox);

    function getLootboxByAddress(address lootbox)
        external
        view
        returns (ILootbox.Lootbox memory);

    function getLootboxByHash(uint256 lootbox)
        external
        view
        returns (ILootbox.Lootbox memory);

    function setLootbox(
        ILootbox.Lootbox memory lootboxData
    ) external;

    function lootboxes() external view returns (ILootbox.Lootbox[] memory);

    function allLootboxes(uint256 index)
        external
        view
        returns (ILootbox.Lootbox memory);

    function allLootboxesLength() external view returns (uint256);

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

    function addTokenSeller(
        address tokenSeller,
        ITokenSeller.TokenSellerInfo memory
    ) external returns (uint256 tokenSellerIndex);

    function getTokenSeller(address tokenSeller)
        external
        view
        returns (ITokenSeller.TokenSellerInfo memory);

    function setTokenSeller(
        address tokenSellerAddress,
        ITokenSeller.TokenSellerInfo memory tokenSellerData
    ) external;

    function tokenSellers()
        external
        view
        returns (ITokenSeller.TokenSellerInfo[] memory);

    function allTokenSellers(uint256 index)
        external
        view
        returns (ITokenSeller.TokenSellerInfo memory);

    function allTokenSellersLength() external view returns (uint256);

    function increaseBuyPrice(address tokenSeller) external view  returns (uint256);
}
