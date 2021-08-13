// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/ITokenPoolQuerier.sol";
import "../interfaces/INFTGemMultiToken.sol";

interface IGemPoolData {
    function allTokenHashesLength() external view returns (uint256);

    function allTokenHashes(uint256 ndx) external view returns (uint256);

    function tokenType(uint256 tokenHash)
        external
        view
        returns (INFTGemMultiToken.TokenType);
}

contract TokenPoolQuerier is ITokenPoolQuerier {
    function getOwnedTokens(
        address gemPool,
        address multitoken,
        address account,
        uint256 page,
        uint256 count
    )
        external
        view
        override
        returns (uint256[] memory claims, uint256[] memory gems)
    {
        uint256 allTokenHashesLength = IGemPoolData(gemPool)
            .allTokenHashesLength();
        require((page * count) <= allTokenHashesLength, "OUT_OF_RANGE");

        uint256 claimLen = 0;
        uint256 gemLen = 0;

        claims = new uint256[](count);
        gems = new uint256[](count);

        for (uint256 i = page * count; i < (page * count) + count; i++) {
            if (i >= allTokenHashesLength) {
                break;
            }
            uint256 claimHash = IGemPoolData(gemPool).allTokenHashes(i);
            INFTGemMultiToken.TokenType tokenType = IGemPoolData(gemPool)
                .tokenType(claimHash);
            uint256 bal = IERC1155(multitoken).balanceOf(account, claimHash);
            if (bal == 0 || claimHash == 0 || claimHash == 1) continue;
            else if (tokenType == INFTGemMultiToken.TokenType.CLAIM)
                claims[claimLen++] = claimHash;
            else if (tokenType == INFTGemMultiToken.TokenType.GEM)
                gems[gemLen++] = claimHash;
        }
    }
}
