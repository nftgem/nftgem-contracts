// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/ITokenPoolQuerier.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/IERC1155.sol";
contract TokenPoolQuerier is ITokenPoolQuerier {

    function getOwnedTokens(address gemPool, address multitoken, address account, uint256 page, uint256 count) external override view returns (uint256[] memory claims, uint256[] memory gems) {
        uint256 allLen = INFTComplexGemPoolData(gemPool).allTokenHashesLength();
        uint256 claimLen = 0;
        uint256 gemLen = 0;

        require((page + 1) * count < allLen, "OUT_OF_RANGE");

        claims = new uint256[](count);
        gems = new uint256[](count);
        claimLen = 0;
        gemLen = 0;

        for(uint256 i = page * count; i < (page * count) + count; i++) {
            uint256 claimHash = INFTComplexGemPoolData(gemPool).allTokenHashes(i);
            uint8 tokenType = INFTComplexGemPoolData(gemPool).tokenType(claimHash);
            uint256 bal = IERC1155(multitoken).balanceOf(account, claimHash);
            if(bal == 0 || claimHash == 0 || claimHash == 1) continue;
            if(tokenType == 1) claims[claimLen++] = claimHash;
            if(tokenType == 2) gems[gemLen++] = claimHash;
        }
    }

}
