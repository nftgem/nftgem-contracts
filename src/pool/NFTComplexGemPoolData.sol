// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/AddressSet.sol";
import "../libs/SafeMath.sol";

import "./ComplexPoolLib.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/INFTGemPoolData.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";

import "hardhat/console.sol";

contract NFTComplexGemPoolData is INFTComplexGemPoolData {
    using SafeMath for uint256;
    using AddressSet for AddressSet.Set;
    using ComplexPoolLib for ComplexPoolLib.ComplexPoolData;

    ComplexPoolLib.ComplexPoolData internal poolData;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            poolData.controllers[msg.sender] == true || msg.sender == poolData.governor || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    constructor() {
        poolData.controllers[msg.sender] = true;
        poolData.controllers[tx.origin] = true;
    }

    /**
     * @dev all the tokenhashes (both claim and gem) for this pool
     */
    function tokenHashes() external view override returns (uint256[] memory) {
        return poolData.tokenHashes;
    }

    /**
     * @dev set all the token hashes for this pool
     */
    function setTokenHashes(uint256[] memory inTokenHashes) external override onlyController {
        poolData.tokenHashes = inTokenHashes;
    }

    /**
     * @dev The symbol for this pool / NFT
     */
    function symbol() external view override returns (string memory) {
        return poolData.symbol;
    }

    /**
     * @dev The ether price for this pool / NFT
     */
    function ethPrice() external view override returns (uint256) {
        return poolData.ethPrice;
    }

    /**
     * @dev max allowable quantity per claim
     */
    function maxQuantityPerClaim() external view override returns (uint256) {
        return poolData.maxQuantityPerClaim;
    }

    /**
     * @dev max claims that can be made on this NFT on any given account
     */
    function maxClaimsPerAccount() external view override returns (uint256) {
        return poolData.maxClaimsPerAccount;
    }

    /**
     * @dev update max quantity per claim
     */
    function setMaxQuantityPerClaim(uint256 maxQty) external override onlyController {
        poolData.maxQuantityPerClaim = maxQty;
    }

    /**
     * @dev update max claims that can be made on this NFT
     */
    function setMaxClaimsPerAccount(uint256 maxCPA) external override onlyController {
        poolData.maxClaimsPerAccount = maxCPA;
    }

    /**
     * @dev returns if pool allows purchase
     */
    function allowPurchase() external view override returns (bool) {
        return poolData.allowPurchase;
    }

    /**
     * @dev set whether pool allows purchase
     */
    function setAllowPurchase(bool allow) external override onlyController {
        poolData.allowPurchase = allow;
    }

    /**
     * @dev is pool enabled (taking claim requests)
     */
    function enabled() external view override returns (bool) {
        return poolData.enabled;
    }

    /**
     * @dev set the enabled status of this pool
     */
    function setEnabled(bool enable) external override onlyController {
        poolData.enabled = enable;
    }

    /**
     * @dev return the appreciation curve of this pool.
     */
    function priceIncrementType() external view override returns (PriceIncrementType) {
        return poolData.priceIncrementType;
    }

    /**
     * @dev set the appreciation curve of this pool.
     */
    function setPriceIncrementType(PriceIncrementType incrementType) external override onlyController {
        poolData.priceIncrementType = incrementType;
    }

    /**
     * @dev return the number of claims made thus far
     */
    function claimedCount() external view override returns (uint256) {
        return poolData.nextClaimIdVal;
    }

    /**
     * @dev return the number of gems made thus far
     */
    function mintedCount() external view override returns (uint256) {
        return poolData.nextGemIdVal;
    }

    /**
     * @dev the total amopunt of staked eth in this pool
     */
    function totalStakedEth() external view override returns (uint256) {
        return poolData.totalStakedEth;
    }

    /**
     * @dev get token type of hash - 1 is for claim, 2 is for gem
     */
    function tokenType(uint256 tokenHash) external view override returns (INFTGemMultiToken.TokenType) {
        return poolData.tokenTypes[tokenHash];
    }

    /**
     * @dev get the claim hash of the gem
     */
    function gemClaimHash(uint256 gemHash) external view override returns (uint256) {
        return poolData.gemClaims[gemHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function tokenId(uint256 tokenHash) external view override returns (uint256) {
        return poolData.tokenIds[tokenHash];
    }

    /**
     * @dev returns a count of all token hashes
     */
    function allTokenHashesLength() external view override returns (uint256) {
        return poolData.tokenHashes.length;
    }

    /**
     * @dev get the token hash at index
     */
    function allTokenHashes(uint256 ndx) external view override returns (uint256) {
        return poolData.tokenHashes[ndx];
    }

    /**
     * @dev return the next claim hash
     */
    function nextClaimHash() external view override returns (uint256) {
        return poolData.nextClaimHash();
    }

    /**
     * @dev return the next gem hash
     */
    function nextGemHash() external view override returns (uint256) {
        return poolData.nextGemHash();
    }

    /**
     * @dev return the next claim id
     */
    function nextClaimId() external view override returns (uint256) {
        return poolData.nextClaimIdVal;
    }

    /**
     * @dev return the next gem id
     */
    function nextGemId() external view override returns (uint256) {
        return poolData.nextGemIdVal;
    }

    /**
     * @dev return the count of allowed tokens
     */
    function allowedTokensLength() external view override returns (uint256) {
        return poolData.allowedTokens.count();
    }

    /**
     * @dev the allowed token address at index
     */
    function allowedTokens(uint256 idx) external view override returns (address) {
        return poolData.allowedTokens.keyAtIndex(idx);
    }

    /**
     * @dev add an allowed token to the pool
     */
    function addAllowedToken(address tkn) external override onlyController {
        poolData.allowedTokens.insert(tkn);
    }

    /**
     * @dev add ad allowed token to the pool
     */
    function removeAllowedToken(address tkn) external override onlyController {
        poolData.allowedTokens.remove(tkn);
    }

    /**
     * @dev is the token in the allowed tokens list
     */
    function isTokenAllowed(address tkn) external view override returns (bool) {
        return poolData.allowedTokens.exists(tkn);
    }

    /**
     * @dev the claim amount for the given claim id
     */
    function claimAmount(uint256 claimHash) external view override returns (uint256) {
        return poolData.claimAmount(claimHash);
    }

    /**
     * @dev the claim quantity (count of gems staked) for the given claim id
     */
    function claimQuantity(uint256 claimHash) external view override returns (uint256) {
        return poolData.claimQuantity(claimHash);
    }

    /**
     * @dev the lock time for this claim. once past lock time a gema is minted
     */
    function claimUnlockTime(uint256 claimHash) external view override returns (uint256) {
        return poolData.claimUnlockTime(claimHash);
    }

    /**
     * @dev claim token amount if paid using erc20
     */
    function claimTokenAmount(uint256 claimHash) external view override returns (uint256) {
        return poolData.claimTokenAmount(claimHash);
    }

    /**
     * @dev the staked token if staking with erc20
     */
    function stakedToken(uint256 claimHash) external view override returns (address) {
        return poolData.stakedToken(claimHash);
    }

    /**
     * @dev set market visibility
     */
    function setVisible(bool isVisible) external override onlyController {
        poolData.visible = isVisible;
    }

    /**
     * @dev set market visibility
     */
    function visible() external view override returns (bool v) {
        v = poolData.visible;
    }

    /**
     * @dev set category category
     */
    function setCategory(uint256 theCategory) external override onlyController {
        poolData.category = theCategory;
    }

    /**
     * @dev get market category
     */
    function category() external view override returns (uint256 c) {
        c = poolData.category;
    }

    /**
     * @dev set description
     */
    function setDescription(string memory desc) external override onlyController {
        poolData.description = desc;
    }

    /**
     * @dev get description
     */
    function description() external view override returns (string memory c) {
        c = poolData.description;
    }

    /**
     * @dev set validate erc20 token against AMM
     */
    function setValidateErc20(bool) external override onlyController {
        poolData.validateerc20 = true;
    }

    /**
     * @dev get validate erc20 token against AMM
     */
    function validateErc20() external view override returns (bool) {
        return poolData.validateerc20;
    }

    /**
     * @dev add an input requirement for this token
     */
    function addInputRequirement(
        address theToken,
        address pool,
        INFTComplexGemPool.RequirementType inputType,
        uint256 theTokenId,
        uint256 minAmount,
        bool takeCustody,
        bool burn
    ) external override onlyController {
        poolData.addInputRequirement(theToken, pool, inputType, theTokenId, minAmount, takeCustody, burn);
    }

    /**
     * @dev add an input requirement for this token
     */
    function updateInputRequirement(
        uint256 ndx,
        address theToken,
        address pool,
        INFTComplexGemPool.RequirementType inputType,
        uint256 tid,
        uint256 minAmount,
        bool takeCustody,
        bool burn
    ) external override onlyController {
        poolData.updateInputRequirement(ndx, theToken, pool, inputType, tid, minAmount, takeCustody, burn);
    }

    /**
     * @dev all Input Requirements Length
     */
    function allInputRequirementsLength() external view override returns (uint256) {
        return poolData.allInputRequirementsLength();
    }

    /**
     * @dev all Input Requirements at element
     */
    function allInputRequirements(uint256 ndx)
        external
        view
        override
        returns (
            address,
            address,
            INFTComplexGemPool.RequirementType,
            uint256,
            uint256,
            bool,
            bool
        )
    {
        return poolData.allInputRequirements(ndx);
    }

    /**
     * @dev add an allowed token source
     */
    function addAllowedTokenSource(address allowedToken) external override {
        if (!poolData.allowedTokenSources.exists(allowedToken)) {
            poolData.allowedTokenSources.insert(allowedToken);
        }
    }

    /**
     * @dev remove an allowed token source
     */
    function removeAllowedTokenSource(address allowedToken) external override {
        if (poolData.allowedTokenSources.exists(allowedToken)) {
            poolData.allowedTokenSources.remove(allowedToken);
        }
    }

    /**
     * @dev returns an array of all allowed token sources
     */
    function allowedTokenSources() external view override returns (address[] memory) {
        return poolData.allowedTokenSources.keyList;
    }

    /**
     * @dev delegate proxy method for multitoken allow
     */
    function proxies(address) external view returns (address) {
        return address(this);
    }

    /**
     * @dev these settings defines how the pool behaves
     */
    function settings()
        external
        view
        override
        returns (
            string memory symbol,
            string memory name,
            string memory description,
            uint256 category,
            uint256 ethPrice,
            uint256 minTime,
            uint256 maxTime,
            uint256 diffstep,
            uint256 maxClaims,
            uint256 maxQuantityPerClaim,
            uint256 maxClaimsPerAccount
        )
    {
        symbol = poolData.symbol;
        name = poolData.name;
        description = poolData.description;
        category = poolData.category;
        ethPrice = poolData.ethPrice;
        minTime = poolData.minTime;
        maxTime = poolData.maxTime;
        diffstep = poolData.diffstep;
        maxClaims = poolData.maxClaims;
        maxQuantityPerClaim = poolData.maxQuantityPerClaim;
        maxClaimsPerAccount = poolData.maxClaimsPerAccount;
    }

    /**
     * @dev these stats reflect the current pool state
     */
    function stats()
        external
        view
        override
        returns (
            bool visible,
            uint256 claimedCount,
            uint256 mintedCount,
            uint256 totalStakedEth,
            uint256 nextClaimHash,
            uint256 nextGemHash,
            uint256 nextClaimId,
            uint256 nextGemId
        )
    {
        visible = poolData.visible;
        claimedCount = poolData.nextClaimIdVal;
        mintedCount = poolData.nextGemIdVal;
        totalStakedEth = poolData.totalStakedEth;
        nextClaimHash = poolData.nextClaimHash();
        nextGemHash = poolData.nextGemHash();
        nextClaimId = poolData.nextClaimIdVal;
        nextGemId = poolData.nextGemIdVal;
    }

    /**
     * @dev return the claim details for the given claim hash
     */
    function claim(uint256 claimHash)
        external
        view
        override
        returns (
            uint256 claimAmount,
            uint256 claimQuantity,
            uint256 claimUnlockTime,
            uint256 claimTokenAmount,
            address stakedToken,
            uint256 nextClaimId
        )
    {
        claimAmount = poolData.claimAmount(claimHash);
        claimQuantity = poolData.claimQuantity(claimHash);
        claimUnlockTime = poolData.claimUnlockTime(claimHash);
        claimTokenAmount = poolData.claimTokenAmount(claimHash);
        stakedToken = poolData.stakedToken(claimHash);
        nextClaimId = poolData.nextClaimIdVal;
    }

    /**
     * @dev return the token data for the given hash
     */
    function token(uint256 tokenHash)
        external
        view
        override
        returns (
            INFTGemMultiToken.TokenType tokenType,
            uint256 tokenId,
            address tokenSource
        )
    {
        tokenType = poolData.tokenTypes[tokenHash];
        tokenId = poolData.tokenIds[tokenHash];
        tokenSource = poolData.tokenSources[tokenHash];
    }

    /**
     * @dev import the legacy gem
     */
    function importLegacyGem(
        address pool,
        address legacyToken,
        uint256 tokenHash,
        address recipient
    ) external override {

        require(tokenHash > 0, "INVALID_TOKENHASH");
        require(pool > address(0), "INVALID_POOL");
        require(legacyToken > address(0), "INVALID_TOKEN");
        require(recipient > address(0), "INVALID_RECIPIENT");
        require(poolData.allowedTokenSources.exists(legacyToken) == true, "INVALID_TOKENSOURCE");
        require(poolData.importedLegacyToken[tokenHash] == false, "ALREADY_IMPORTED");

        bytes32 importedSymHash = keccak256(abi.encodePacked(INFTGemPoolData(pool).symbol()));
        bytes32 poolSymHash = keccak256(abi.encodePacked(poolData.symbol));
        require(importedSymHash == poolSymHash, "INVALID_POOLHASH");

        INFTGemMultiToken.TokenType importTokenType = INFTGemPoolData(pool).tokenType(tokenHash);
        require(importTokenType == INFTGemMultiToken.TokenType.GEM, "INVALID_TOKENTYPE");

        uint256 quantity = IERC1155(legacyToken).balanceOf(recipient, tokenHash);
        uint256 importTokenId = INFTGemPoolData(pool).tokenId(tokenHash);

        if(quantity > 0) {
            INFTGemMultiToken(poolData.multitoken).mint(recipient, tokenHash, quantity);
            INFTGemMultiToken(poolData.multitoken).setTokenData(tokenHash, INFTGemMultiToken.TokenType.GEM, address(this));

            poolData.tokenTypes[tokenHash] = INFTGemMultiToken.TokenType.GEM;
            poolData.tokenIds[tokenHash] = importTokenId;
            poolData.tokenSources[tokenHash] = legacyToken;
            poolData.importedLegacyToken[tokenHash] = true;

            INFTGemGovernor(poolData.governor).maybeIssueGovernanceToken(msg.sender);
            emit NFTGemImported(msg.sender, address(this), pool, legacyToken, tokenHash, quantity);
        }
    }

    /**
     * @dev returns if legacy gem with given hash is imported
     */
    function isLegacyGemImported(uint256 tokenhash) external view override returns (bool isImported) {
        isImported = poolData.importedLegacyToken[tokenhash];
    }

    /**
     * @dev set the next claim and gem ids
     */
    function setNextIds(uint256 _nextClaimId, uint256 _nextGemId) external override onlyController {
        poolData.nextClaimIdVal = _nextClaimId;
        poolData.nextGemIdVal = _nextGemId;
    }
}
