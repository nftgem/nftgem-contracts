// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./INFTGemMultiToken.sol";

/// @dev The gem indexer indexes all historical gems from legacy contracts and
/// produces a series of events that get indexed by thegraph indexer. this is
/// necessary because the legacy contracts generate events from library code,
/// making things not work in thegraph.

interface IGemPoolData {
    function allTokenHashesLength() external view returns (uint256);

    function allTokenHashes(uint256 ndx) external view returns (uint256);

    function tokenType(uint256 tokenHash)
        external
        view
        returns (INFTGemMultiToken.TokenType);

    function settings()
        external
        view
        returns (
            string memory settingsSymbol,
            string memory settingsName,
            string memory settingsDescription,
            uint256 settingsCategory,
            uint256 settingsEthPrice,
            uint256 settingsMinTime,
            uint256 settingsMaxTime,
            uint256 settingsDiffStep,
            uint256 settingsMacClaims,
            uint256 settingsMaxQuantityPerClaim,
            uint256 settingsMaxClaimsPerAccount
        );
}

interface IBitgemIndexer {
    struct GemPoolFactory {
        address factoryAddress;
    }
    struct GemPool {
        address factory;
        address multitoken;
        address poolAddress;
        string symbol;
        string name;
        string description;
        uint256 category;
        uint256 ethPrice;
    }
    struct Gem {
        uint256 id;
        string symbol;
        string name;
        uint256 gemHash;
        address pool;
        address minter;
        address gemPoolFactory;
        address multitoken;
        uint256 quantity;
    }
    struct LootboxFactory {
        address factoryAddress;
    }
    struct Lootbox {
        address poolAddress;
        string symbol;
        string name;
        string description;
        address factory;
        address multitoken;
        uint256 quantity;
    }
    struct Loot {
        uint256 id;
        string symbol;
        string name;
        string description;
        uint256 lootHash;
        uint256 lootbox;
        address minter;
        address factory;
        address multitoken;
        uint256 probability;
        uint256 quantity;
    }
    struct SwapMeet {
        address swapMeetAddress;
    }
    struct Offer {
        uint256 id;
        address swapMeet;
        address owner;
        address pool;
        uint256 gem;
        uint256 quantity;
        address[] pools;
        uint256[] gems;
        uint256[] quantities;
        uint256 listingFee;
        uint256 acceptFee;
        uint256 references;
        bool missingTokenPenalty;
    }
    event GemCreated(uint256 indexed gemCreateUID, GemPool pool, Gem gem);
    event LootboxOpened(
        address opener,
        LootboxFactory factory,
        Lootbox lootbox,
        Loot[] receivedLoot
    );

    function indexGem(GemPool memory gemPool, Gem memory gem)
        external
        returns (bool);

    function indexGemUnsafe(GemPool memory gemPool, Gem memory gem) external;

    function getOwnedGems(
        address gemPool,
        address multitoken,
        address account,
        uint256 page,
        uint256 count
    ) external view returns (uint256[] memory gems, uint256 gemLen);

    function indexGemPool(
        address gemPool,
        address multitoken,
        uint256 page,
        uint256 count
    ) external returns (Gem[] memory gems);
}
