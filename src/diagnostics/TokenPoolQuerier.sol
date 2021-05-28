// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/ITokenPoolQuerier.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/IERC1155.sol";
contract TokenPoolQuerier is ITokenPoolQuerier {

    function getOwnedTokens(address gemPool, address multitoken, address account) external override view returns (uint256[] memory claims, uint256[] memory gems) {
        uint256 allLen = INFTComplexGemPoolData(gemPool).allTokenHashesLength();
        uint256 claimLen = 0;
        uint256 gemLen = 0;

        for(uint256 i = 0; i < allLen; i++) {
            uint256 claimHash = INFTComplexGemPoolData(gemPool).allTokenHashes(i);
            uint8 tokenType = INFTComplexGemPoolData(gemPool).tokenType(claimHash);
            if(tokenType == 1) claimLen = claimLen + 1;
            if(tokenType == 2) gemLen = gemLen + 1;
        }

        claims = new uint256[](claimLen);
        gems = new uint256[](gemLen);
        claimLen = 0;
        gemLen = 0;

        for(uint256 i = 0; i < allLen; i++) {
            uint256 claimHash = INFTComplexGemPoolData(gemPool).allTokenHashes(i);
            uint8 tokenType = INFTComplexGemPoolData(gemPool).tokenType(claimHash);
            uint256 bal = IERC1155(multitoken).balanceOf(account, claimHash);
            if(bal == 0) continue;
            if(tokenType == 1) claims[claimLen++] = claimHash;
            if(tokenType == 2) gems[gemLen++] = claimHash;
        }
    }

}
