// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./INFTGemMultiToken.sol";
import "./INFTComplexGemPool.sol";

interface INFTComplexGemPoolData {
    enum PriceIncrementType {
        COMPOUND,
        INVERSELOG,
        NONE
    }

    /**
     * @dev a requirement of erc20, erc1155, or nft gem
     */
    struct InputRequirement {
        address token;
        address pool;
        INFTComplexGemPool.RequirementType inputType; // 1 = erc20, 2 = erc1155, 3 = pool
        uint256 tokenId; // if erc20 slot 0 contains required amount
        uint256 minVal;
        bool takeCustody;
        bool burn;
        bool exactAmount;
    }

    /**
     * @dev Event generated when an NFT claim is imported from a legacy contract
     */
    event NFTGemImported(
        address indexed converter,
        address indexed pool,
        address oldPool,
        address oldToken,
        uint256 indexed gemHash,
        uint256 quantity
    );

    function addInputRequirement(
        address theToken,
        address pool,
        INFTComplexGemPool.RequirementType inputType,
        uint256 theTokenId,
        uint256 minAmount,
        bool takeCustody,
        bool burn,
        bool exactAmount
    ) external;

    function updateInputRequirement(
        uint256 ndx,
        address theToken,
        address pool,
        INFTComplexGemPool.RequirementType inputType,
        uint256 tid,
        uint256 minAmount,
        bool takeCustody,
        bool burn,
        bool exactAmount
    ) external;

    function allInputRequirementsLength() external returns (uint256);

    function allInputRequirements(uint256 ndx)
        external
        view
        returns (
            address,
            address,
            INFTComplexGemPool.RequirementType,
            uint256,
            uint256,
            bool,
            bool,
            bool
        );

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

    function stats()
        external
        view
        returns (
            bool statsVisible,
            uint256 statsClaimedCount,
            uint256 statsMintedCount,
            uint256 statsTotalStakedEth,
            uint256 statsNextClaimHash,
            uint256 statsNextGemHash,
            uint256 statsNextClaimId,
            uint256 statsNextGemId
        );

    function claim(uint256 claimHash)
        external
        view
        returns (
            uint256 claimClaimAmount,
            uint256 claimClaimQuantity,
            uint256 claimClaimUnlockTime,
            uint256 claimClaimTokenAmount,
            uint256 claimClaimTokenSource,
            address claimStakedToken,
            uint256 claimNextClaimId
        );

    function token(uint256 tokenHash)
        external
        view
        returns (
            INFTGemMultiToken.TokenType tokenTokenType,
            uint256 tokenTokenId,
            address tokenTokenSource
        );

    function addAllowedTokenSource(address allowedToken) external;

    function removeAllowedTokenSource(address allowedToken) external;

    function allowedTokenSources() external view returns (address[] memory);

    function importLegacyGem(
        address pool,
        address legacyToken,
        uint256 tokenHash,
        address recipient
    ) external;

    function isLegacyGemImported(uint256 tokenhash)
        external
        view
        returns (bool);

    function setNextIds(uint256 _nextClaimId, uint256 _nextGemId) external;

    function tokenHashes() external view returns (uint256[] memory);

    function setTokenHashes(uint256[] memory inTokenHashes) external;

    // pool is inited with these parameters. Once inited, all
    // but ethPrice are immutable. ethPrice only increases. ONLY UP
    function symbol() external view returns (string memory);

    function ethPrice() external view returns (uint256);

    function setVisible(bool isVisible) external;

    function visible() external view returns (bool);

    function setCategory(uint256 theCategory) external;

    function category() external view returns (uint256);

    function setDescription(string memory desc) external;

    function description() external view returns (string memory);

    // these describe the pools created contents over time. This is where
    // you query to get information about a token that a pool created
    function claimedCount() external view returns (uint256);

    function claimAmount(uint256 claimId) external view returns (uint256);

    function claimQuantity(uint256 claimId) external view returns (uint256);

    function maxQuantityPerClaim() external view returns (uint256);

    function maxClaimsPerAccount() external view returns (uint256);

    function setMaxQuantityPerClaim(uint256 claimId) external;

    function setMaxClaimsPerAccount(uint256 claimId) external;

    function mintedCount() external view returns (uint256);

    function totalStakedEth() external view returns (uint256);

    function tokenId(uint256 tokenHash) external view returns (uint256);

    function tokenType(uint256 tokenHash)
        external
        view
        returns (INFTGemMultiToken.TokenType);

    function allTokenHashesLength() external view returns (uint256);

    function allTokenHashes(uint256 ndx) external view returns (uint256);

    function nextClaimHash() external view returns (uint256);

    function nextGemHash() external view returns (uint256);

    function nextGemId() external view returns (uint256);

    function nextClaimId() external view returns (uint256);

    function setValidateErc20(bool) external;

    function validateErc20() external view returns (bool);

    function claimUnlockTime(uint256 claimId) external view returns (uint256);

    function claimTokenAmount(uint256 claimId) external view returns (uint256);

    function gemClaimHash(uint256 gemHash) external view returns (uint256);

    function stakedToken(uint256 claimId) external view returns (address);

    function allowedTokensLength() external view returns (uint256);

    function allowedTokens(uint256 idx) external view returns (address);

    function isTokenAllowed(address tkn) external view returns (bool);

    function addAllowedToken(address tkn) external;

    function removeAllowedToken(address tkn) external;

    function allowPurchase() external view returns (bool);

    function setAllowPurchase(bool allow) external;

    function enabled() external view returns (bool);

    function setEnabled(bool enable) external;

    function priceIncrementType() external view returns (PriceIncrementType);

    function setPriceIncrementType(PriceIncrementType incrementType) external;
}
