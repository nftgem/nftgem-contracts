// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/AddressSet.sol";
import "../libs/SafeMath.sol";
import "../interfaces/INFTGemPoolData.sol";
import "../interfaces/INFTGemMultitoken.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";

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

    /**
     * @dev check the input requirements for the token - return true if requirements are met
     */
    function checkInputRequirements(address account) internal returns (bool) {
        for (uint256 i = 0; i < inputRequirements.length; i++) {
            if (inputRequirements[i].inputType == 1) {
                IERC20 token = IERC20(inputRequirements[i].token);
                uint256 bal = token.balanceOf(account);
                if (bal < inputRequirements[i].minVal) {
                    return false;
                }
            } else if (inputRequirements[i].inputType == 2) {
                IERC1155 token = IERC1155(inputRequirements[i].token);
                uint256 bal = token.balanceOf(account, inputRequirements[i].tokenId);
                if (bal < inputRequirements[i].minVal) {
                    return false;
                }
            } else if (inputRequirements[i].inputType == 3) {
                IERC1155 token = IERC1155(inputRequirements[i].token);
                INFTGemPoolData pool = INFTGemPoolData(inputRequirements[i].pool);
                uint256 required = inputRequirements[i].minAmount
                uint256 hashCount = INFTGemMultitoken(token).heldTokensLength(account);
                for (uint256 j = 0; i < hasCount; j++) {
                    uint256 hashAt = INFTGemMultitoken(token).heldTokens(account, j);
                    if(pool.tokenType(hashAt) == 2) {

                    }
                }
                uint256 bal = token.balanceOf(account, inputRequirements[i].tokenId);
                if (bal < inputRequirements[i].minVal) {
                    return false;
                }
            }
        }
        return true;
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
}
