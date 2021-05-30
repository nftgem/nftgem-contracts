// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../libs/SafeMath.sol";

import "../interfaces/IERC1155.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC20WrappedGem.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTComplexGemPoolData.sol";

import "hardhat/console.sol";

library WrappedTokenLib {
    using SafeMath for uint256;

    event Wrap(address indexed account, uint256 quantity);
    event Unwrap(address indexed account, uint256 quantity);

    struct WrappedTokenData {
        address erc1155token;
        address erc20token;
        address tokenPool;
        uint256 index;
        uint256 wrappedBalance;
        INFTGemMultiToken.TokenType tokenType;
        uint256 rate;
        mapping(address => uint256[]) ids;
        mapping(address => uint256[]) amounts;
    }

    function getPoolTypeBalance(
        address erc1155token,
        address tokenPool,
        INFTGemMultiToken.TokenType tokenType,
        address account
    ) public view returns (uint256 tq) {
        uint256[] memory ht = INFTGemMultiToken(erc1155token).heldTokens(account);
        for (uint256 i = ht.length - 1; i >= 0; i = i.sub(1)) {
            uint256 tokenHash = ht[i];
            (INFTGemMultiToken.TokenType _tokenType, address _tokenPool) = INFTGemMultiToken(erc1155token).getTokenData(tokenHash);
            if (_tokenType == tokenType && _tokenPool == tokenPool) {
                uint256 oq = IERC1155(erc1155token).balanceOf(account, tokenHash);
                tq = tq.add(oq);
            }
            if (i == 0) break;
        }
    }

    function transferPoolTypesFrom(
        WrappedTokenData storage self,
        address from,
        address to,
        uint256 quantity
    ) public {
        uint256 tq = quantity;
        delete self.ids[to];
        delete self.amounts[to];

        uint256[] memory ht = INFTGemMultiToken(self.erc1155token).heldTokens(from);
        for (uint256 i = ht.length - 1; i >= 0 && tq > 0; i = i.sub(1)) {
            uint256 tokenHash = ht[i];
            (INFTGemMultiToken.TokenType _tokenType, address _tokenPool) = INFTGemMultiToken(self.erc1155token).getTokenData(tokenHash);
            if (_tokenType == self.tokenType && _tokenPool == self.tokenPool) {
                uint256 oq = IERC1155(self.erc1155token).balanceOf(from, tokenHash);
                uint256 toTransfer = oq > tq ? tq : oq;
                self.ids[to].push(tokenHash);
                self.amounts[to].push(toTransfer);
                tq = tq.sub(toTransfer);
            }
            if (i == 0) break;
        }

        require(tq == 0, "INSUFFICIENT_GEMS");

        IERC1155(self.erc1155token).safeBatchTransferFrom(from, to, self.ids[to], self.amounts[to], "");
    }
}
