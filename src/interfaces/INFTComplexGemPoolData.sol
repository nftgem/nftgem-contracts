// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "./INFTGemPoolData.sol";

interface INFTComplexGemPoolData is INFTGemPoolData {
    function addInputRequirement(
        address token,
        address pool,
        uint8 inputType,
        uint256 tokenId,
        uint256 minAmount,
        bool burn
    ) external;
}
