// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface INFTComplexGemPoolData {

    enum PriceIncrementType {COMPOUND, NONE}

    function addInputRequirement(
        address token,
        address pool,
        uint8 inputType,
        uint256 tokenId,
        uint256 minAmount,
        bool burn
    ) external;

    function updateInputRequirement(
        uint256 ndx,
        address token,
        address pool,
        uint8 inputType,
        uint256 tid,
        uint256 minAmount,
        bool burn
    ) external;

    function allInputRequirementsLength() external returns (uint256);

    function allInputRequirements(uint256 ndx)
        external
        view
        returns (
            address,
            address,
            uint8,
            uint256,
            uint256,
            bool
        );

    function settings()
        external
        view
        returns (
            string memory symbol,
            string memory name,
            string memory description,
            uint256 category,
            uint256 ethPrice,
            uint256 minTime,
            uint256 maxTime,
            uint256 diffStep,
            uint256 macClaims,
            uint256 maxQuantityPerClaim,
            uint256 maxClaimsPerAccount
        );

    function stats()
        external
        view
        returns (
            bool visible,
            uint256 claimedCount,
            uint256 mintedCount,
            uint256 totalStakedEth,
            uint256 nextClaimHash,
            uint256 nextGemHash,
            uint256 nextClaimId,
            uint256 nextGemId
        );

    function claim(uint256 claimHash)
        external
        view
        returns (
            uint256 claimAmount,
            uint256 claimQuantity,
            uint256 claimUnlockTime,
            uint256 claimTokenAmount,
            address stakedToken,
            uint256 nextClaimId
        );

    function token(uint256 tokenHash) external view returns (uint8 tokenType, uint256 tokenId, address tokenSource);

    function addAllowedTokenSource(address allowedToken) external;

    function removeAllowedTokenSource(address allowedToken) external;

    function allowedTokenSources() external returns (address[] memory);

    function addLegacyToken(
        address token,
        uint8 tokenType,
        uint256 tokenHash,
        uint256 tokenId,
        address recipient,
        uint256 quantity
    ) external;

    function setToken(
        uint256 tokenHash,
        uint8 tokenType,
        uint256 tokenId
    ) external;

    function setNextIds(uint256 nextClaimId, uint256 nextGemId) external;

    function tokenHashes() external view returns (uint256[] memory);

    function setTokenHashes(uint256[] memory tokenHashes) external;

    // pool is inited with these parameters. Once inited, all
    // but ethPrice are immutable. ethPrice only increases. ONLY UP
    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function ethPrice() external view returns (uint256);

    function minTime() external view returns (uint256);

    function maxTime() external view returns (uint256);

    function difficultyStep() external view returns (uint256);

    function maxClaims() external view returns (uint256);

    function setVisible(bool visible) external;

    function visible() external view returns (bool);

    function setCategory(uint256 category) external;

    function category() external view returns (uint256);

    function setDescription(string memory description) external;

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

    function tokenType(uint256 tokenHash) external view returns (uint8);

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

    function allowPurchase() external view  returns (bool);

    function setAllowPurchase(bool allow) external;

    function priceIncrementType() external view  returns (PriceIncrementType);

    function setPriceIncrementType(PriceIncrementType incrementType) external;
}
