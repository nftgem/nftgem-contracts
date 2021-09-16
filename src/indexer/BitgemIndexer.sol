// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../access/Controllable.sol";
import "../interfaces/ITokenSeller.sol";
import "../interfaces/IBitgemIndexer.sol";

/// @dev The gem indexer indexes all historical gems from legacy contracts and
/// produces a series of events that get indexed by thegraph indexer. this is
/// necessary because the legacy contracts generate events from library code,
/// making things not work in thegraph.

/// @title A title that should describe the contract/interface
/// @author The name of the author
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract BitgemIndexer is IBitgemIndexer, Controllable {
    mapping(uint256 => Gem) public gemMap;
    mapping(address => Gem[]) public gemsByMinter;
    mapping(address => Gem[]) public gemsByFactory;
    mapping(address => Gem[]) public gemsByMultitoken;
    mapping(address => Gem[]) public gemsByPool;

    GemPool[] public gemPools;
    mapping(address => GemPool) public gemPoolsMap;
    mapping(address => GemPool) public gemPoolFactoriesMap;

    constructor() {
        _addController(address(this));
    }

    function _makeId(Gem memory gem) internal pure returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        gem.gemHash,
                        gem.minter,
                        gem.gemPoolFactory,
                        gem.multitoken,
                        gem.pool,
                        gem.quantity
                    )
                )
            );
    }

    function indexGemPool(
        address gemPool,
        address multitoken,
        uint256 page,
        uint256 count
    ) external override returns (Gem[] memory gems) {
        uint256 allTokenHashesLength = IGemPoolData(gemPool)
            .allTokenHashesLength();
        require((page * count) + count <= allTokenHashesLength, "OUT_OF_RANGE");

        uint256 gemLen = 0;
        gems = new Gem[](count);

        for (
            uint256 i = page * count;
            i < ((page * count) + count) && i < allTokenHashesLength;
            i++
        ) {
            uint256 claimHash = 0;
            try IGemPoolData(gemPool).allTokenHashes(i) returns (
                uint256 _claimHash
            ) {
                claimHash = _claimHash;
            } catch {
                continue;
            }

            INFTGemMultiToken.TokenType tokenType = IGemPoolData(gemPool)
                .tokenType(claimHash);

            if (tokenType == INFTGemMultiToken.TokenType.GEM) {
                uint256 allTokenHoldersLength = INFTGemMultiToken(multitoken)
                    .allTokenHoldersLength(claimHash);
                if (allTokenHoldersLength != 0) {
                    for (uint256 j = 0; j < allTokenHoldersLength; j++) {
                        (
                            GemPool memory _gemPool,
                            Gem memory _gem
                        ) = _createGemObjects(
                                multitoken,
                                gemPool,
                                i,
                                claimHash
                            );
                        if (_indexGem(_gemPool, _gem)) {
                            gems[gemLen++] = _gem;
                        }
                    }
                }
            }
        }
    }

    function _createGemObjects(
        address multitoken,
        address gemPool,
        uint256 i,
        uint256 claimHash
    ) internal view returns (GemPool memory _gemPool, Gem memory _gem) {
        address holder = INFTGemMultiToken(multitoken).allTokenHolders(
            i,
            claimHash
        );
        (
            string memory settingsSymbol,
            string memory settingsName,
            string memory settingsDescription,
            uint256 settingsCategory,
            uint256 settingsEthPrice,
            ,
            ,
            ,
            ,
            ,

        ) = IGemPoolData(gemPool).settings();
        _gemPool = GemPool(
            uint256(uint160(gemPool)),
            address(0),
            multitoken,
            gemPool,
            settingsSymbol,
            settingsName,
            settingsDescription,
            settingsCategory,
            settingsEthPrice
        );
        uint256 balance = IERC1155(multitoken).balanceOf(holder, claimHash);
        if (balance != 0) {
            _gem = Gem(
                0,
                settingsSymbol,
                settingsName,
                claimHash,
                holder,
                gemPool,
                multitoken,
                gemPool,
                balance
            );
            _gem.id = _makeId(_gem);
        }
    }

    function getOwnedGems(
        address gemPool,
        address multitoken,
        address account,
        uint256 page,
        uint256 count
    ) external view override returns (uint256[] memory gems, uint256 gemLen) {
        gems = new uint256[](count);

        for (uint256 i = page * count; i < (page * count) + count; i++) {
            uint256 claimHash = 0;
            try IGemPoolData(gemPool).allTokenHashes(i) returns (
                uint256 _claimHash
            ) {
                claimHash = _claimHash;
            } catch {
                continue;
            }

            INFTGemMultiToken.TokenType tokenType = IGemPoolData(gemPool)
                .tokenType(claimHash);

            uint256 bal = IERC1155(multitoken).balanceOf(account, claimHash);
            if (
                tokenType != INFTGemMultiToken.TokenType.GEM ||
                bal == 0 ||
                claimHash == 0 ||
                claimHash == 1
            ) continue;

            gems[gemLen++] = claimHash;
        }
    }

    function _indexGem(GemPool memory gemPool, Gem memory gem)
        internal
        returns (bool)
    {
        uint256 gemId = _makeId(gem);
        if (gemMap[gemId].id != 0) {
            return false;
        }
        gem.id = gemId;
        gemMap[gemId] = gem;
        gemsByMinter[gem.minter].push(gem);
        if (gemsByFactory[gem.gemPoolFactory].length == 0) {
            FactoryCreated(gem.gemPoolFactory);
        }
        gemsByFactory[gem.gemPoolFactory].push(gem);
        gemsByMultitoken[gem.multitoken].push(gem);
        gemsByPool[gem.pool].push(gem);
        if (gemPoolsMap[gem.pool].multitoken == address(0)) {
            gemPoolsMap[gem.pool] = gemPool;
            gemPools.push(gemPool);
            emit PoolCreated(
                gemPool.factory,
                gemPool.multitoken,
                gemPool.poolAddress,
                gemPool.symbol,
                gemPool.name,
                gemPool.description,
                gemPool.category,
                gemPool.ethPrice
            );
        }
        emit GemCreated(
            gem.id,
            gem.symbol,
            gem.name,
            gem.gemHash,
            gem.pool,
            gem.minter,
            gem.gemPoolFactory,
            gem.multitoken,
            gem.quantity
        );
        return true;
    }

    function indexGem(GemPool memory gemPool, Gem memory gem)
        external
        override
        returns (bool)
    {
        return _indexGem(gemPool, gem);
    }

    function indexGems(GemPool[] memory gemPools, Gem[] memory gems)
        external
        override
    {
        for (uint256 i = 0; i < gems.length; i++) {
            _indexGem(gemPools[i], gems[i]);
        }
    }

    function indexBulkGems(GemPool[] memory gemPools, Gem[] memory gems)
        external
        override
    {
        emit BulkGemCreated(gemPools, gems);
    }
}
