// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../access/Controllable.sol";
import "./ITokenSeller.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../interfaces/INFTGemMultiToken.sol";

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
}

interface IBitgemIndexer {
    struct Gem {
        uint256 id;
        uint256 gemHash;
        address minter;
        address gemPoolFactory;
        address multitoken;
        address pool;
        uint256 quantity;
    }

    event GemCreated(
        uint256 indexed gemCreateUID,
        uint256 gemHash,
        address minter,
        address gemPoolFactory,
        address multitoken,
        address pool,
        uint256 quantity,
        Gem gem
    );

    function indexGem(
        Gem memory gem
    ) external returns (bool);

    function indexGems(
        Gem[] memory gem
    ) external returns (bool);

    function getOwnedGems(
        address gemPool,
        address multitoken,
        address account,
        uint256 page,
        uint256 count
    )
        external
        view
        returns (uint256[] memory gems);


    function indexGemPool(
        address gemPool,
        address multitoken,
        uint256 page,
        uint256 count
       )
        external
        returns (Gem[] memory gems);

}

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

    constructor() {
        _addController(address(this));
    }

    function _makeId(Gem memory gem) internal pure returns (uint256) {
        return uint256(
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
    )
        external
        override
        returns (Gem[] memory gems)
    {
        uint256 allTokenHashesLength = IGemPoolData(gemPool)
            .allTokenHashesLength();
        require((page * count) + count <= allTokenHashesLength, "OUT_OF_RANGE");

        uint256 gemLen = 0;
        gems = new Gem[](count);

        for (uint256 i = page * count; i < ( (page * count) + count) && i < allTokenHashesLength; i++) {

            uint256 claimHash = 0;
            try IGemPoolData(gemPool).allTokenHashes(i) returns (uint256 _claimHash) {
                claimHash = _claimHash;
            } catch {
                continue;
            }

            INFTGemMultiToken.TokenType tokenType = IGemPoolData(gemPool)
                .tokenType(claimHash);

            if (tokenType != INFTGemMultiToken.TokenType.GEM
                || claimHash == 0
                || claimHash == 1) continue;

            if (tokenType == INFTGemMultiToken.TokenType.GEM) {
                uint256 allTokenHoldersLength = INFTGemMultiToken(multitoken).allTokenHoldersLength(claimHash);
                if(allTokenHoldersLength != 0) {
                    for (uint256 j = 0; j < allTokenHoldersLength; j++) {
                        Gem memory _gem = _doIt(multitoken, gemPool, i, claimHash);
                        if(_indexGem(_gem)) {
                            gems[gemLen++] = _gem;
                        }
                    }
                }
            }

        }
    }

    function _doIt(address multitoken, address gemPool, uint i, uint256 claimHash) internal view returns (Gem memory _gem) {
        address holder = INFTGemMultiToken(multitoken).allTokenHolders(i, claimHash);
        uint256 balance = IERC1155(multitoken).balanceOf(holder, claimHash);
        if(balance != 0) {
            _gem = Gem(
                0,
                claimHash,
                holder,
                gemPool,
                multitoken,
                gemPool,
                balance
            );
            _gem.id =_makeId(_gem);
        }
    }

    function getOwnedGems(
        address gemPool,
        address multitoken,
        address account,
        uint256 page,
        uint256 count
    )
        external
        view
        override
        returns (uint256[] memory gems)
    {
        uint256 gemLen = 0;
        gems = new uint256[](count);

        for (uint256 i = page * count; i < (page * count) + count; i++) {

            uint256 claimHash = 0;
            try IGemPoolData(gemPool).allTokenHashes(i) returns (uint256 _claimHash) {
                claimHash = _claimHash;
            } catch {
                continue;
            }

            INFTGemMultiToken.TokenType tokenType = IGemPoolData(gemPool)
                .tokenType(claimHash);

            uint256 bal = IERC1155(multitoken).balanceOf(account, claimHash);
            if (tokenType != INFTGemMultiToken.TokenType.GEM
                || bal == 0
                || claimHash == 0
                || claimHash == 1) continue;

            if (tokenType == INFTGemMultiToken.TokenType.GEM)
                gems[gemLen++] = claimHash;
        }
    }

    function _indexGem(
        Gem memory gem
    ) internal returns (bool) {
        uint256 gemId = _makeId(gem);
        if (gemMap[gemId].gemHash != 0) {
            return false;
        }
        gem.id = gemId;
        gemMap[gemId] = gem;
        gemsByMinter[gem.minter].push(gem);
        gemsByFactory[gem.gemPoolFactory].push(gem);
        gemsByMultitoken[gem.multitoken].push(gem);
        gemsByPool[gem.pool].push(gem);
        emit GemCreated(
            gem.id,
            gem.gemHash,
            gem.minter,
            gem.gemPoolFactory,
            gem.multitoken,
            gem.pool,
            gem.quantity,
            gem
        );
        return true;
    }


    function indexGem(
        Gem memory gem
    ) external override returns (bool) {
        return _indexGem(gem);
    }

    function indexGems(
        Gem[] memory gem
    ) external override returns (bool) {
        bool success = true;
        for (uint256 i = 0; i < gem.length; i++) {
            success = success && _indexGem(gem[i]);
        }
        return success;
    }

}
