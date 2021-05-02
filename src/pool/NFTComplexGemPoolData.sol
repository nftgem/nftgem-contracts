// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/AddressSet.sol";
import "../libs/SafeMath.sol";
import "../interfaces/INFTGemPoolData.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";

import "./NFTGemPoolData.sol";

import "hardhat/console.sol";

contract NFTComplexGemPoolData is NFTGemPoolData, INFTComplexGemPoolData {
    struct InputRequirement {
        address token;
        address pool;
        uint8 inputType; // 1 = erc20, 2 = erc1155, 3 = pool
        uint256 tokenId; // if erc20 slot 0 contains required amount
        uint256 minVal;
        bool burn;
    }
    InputRequirement[] internal inputRequirements;

    mapping(uint256 => uint256[]) internal claimIds;
    mapping(uint256 => uint256[]) internal claimQuantities;

    /**
     * @dev Transfer a quantity of input reqs from to
     */
    function transferInputReqsFrom(
        uint256 claimHash,
        address from,
        address to,
        uint256 quantity
    ) internal {
        address token;

        for (uint256 i = 0; i < inputRequirements.length; i++) {
            if (inputRequirements[i].inputType == 1) {
                IERC20 token = IERC20(inputRequirements[i].token);
                token.transferFrom(from, to, inputRequirements[i].minVal);
            } else if (inputRequirements[i].inputType == 2) {
                IERC1155 token = IERC1155(inputRequirements[i].token);
                token.safeTransferFrom(from, to, inputRequirements[i].tokenId, inputRequirements[i].minVal, "");
            } else if (inputRequirements[i].inputType == 3) {
                uint256 required = inputRequirements[i].minVal * quantity;
                uint256 hashCount = INFTGemMultiToken(inputRequirements[i].token).allHeldTokensLength(from);
                for (uint256 j = 0; j < hashCount; j++) {
                    uint256 hashAt = INFTGemMultiToken(inputRequirements[i].token).allHeldTokens(from, j);
                    if (INFTGemPoolData(inputRequirements[i].pool).tokenType(hashAt) == 2) {
                        token = inputRequirements[i].token;
                        uint256 bal = IERC1155(inputRequirements[i].token).balanceOf(from, hashAt);
                        if (bal > required) {
                            bal = required;
                        }
                        if (bal == 0) {
                            continue;
                        }
                        claimIds[claimHash].push(hashAt);
                        claimQuantities[claimHash].push(bal);
                        required = required - bal;
                    }
                    if (required == 0) {
                        break;
                    }
                }
                require(required == 0, "INSUFFICIENT_QUANTITIY");
            }
        }

        if (claimIds[claimHash].length > 0) {
            IERC1155(token).safeBatchTransferFrom(from, to, claimIds[claimHash], claimQuantities[claimHash], "");
        }
    }

    /**
     * @dev add an input requirement for this token
     */
    function addInputRequirement(
        address token,
        address pool,
        uint8 inputType,
        uint256 tokenId,
        uint256 minAmount,
        bool burn
    ) external override {
        require(token != address(0), "INVALID_TOKEN");
        require(inputType == 1 || inputType == 2 || inputType == 3, "INVALID_TOKENTYPE");
        require((inputType == 3 && pool != address(0)) || inputType != 3, "INVALID_POOL");
        require(
            (inputType == 1 && tokenId == 0) || inputType == 2 || (inputType == 3 && tokenId == 0),
            "INVALID_TOKENID"
        );
        require(minAmount != 0, "ZERO_AMOUNT");
        inputRequirements.push(InputRequirement(token, pool, inputType, tokenId, minAmount, burn));
    }

    function proxies(address) external view returns (address) {
        return address(this);
    }
}
