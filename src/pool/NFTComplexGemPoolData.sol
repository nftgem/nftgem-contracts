// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/AddressSet.sol";
import "../libs/SafeMath.sol";

import "./ComplexPoolLib.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
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
     * @dev The symbol for this pool / NFT
     */
    function tokenHashes() external view override returns (uint256[] memory) {
        return poolData.tokenHashes;
    }

    /**
     * @dev The symbol for this pool / NFT
     */
    function setTokenHashes(uint256[] memory tokenHashes) external override onlyController {
        poolData.tokenHashes = tokenHashes;
    }

    /**
     * @dev The symbol for this pool / NFT
     */
    function symbol() external view override returns (string memory) {
        return poolData.symbol;
    }

    /**
     * @dev The name for this pool / NFT
     */
    function name() external view override returns (string memory) {
        return poolData.name;
    }

    /**
     * @dev The ether price for this pool / NFT
     */
    function ethPrice() external view override returns (uint256) {
        return poolData.ethPrice;
    }

    /**
     * @dev min time to stake in this pool to earn an NFT
     */
    function minTime() external view override returns (uint256) {
        return poolData.minTime;
    }

    /**
     * @dev max time to stake in this pool to earn an NFT
     */
    function maxTime() external view override returns (uint256) {
        return poolData.maxTime;
    }

    /**
     * @dev difficulty step increase for this pool.
     */
    function difficultyStep() external view override returns (uint256) {
        return poolData.diffstep;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function maxClaims() external view override returns (uint256) {
        return poolData.maxClaims;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function maxQuantityPerClaim() external view override returns (uint256) {
        return poolData.maxQuantityPerClaim;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function maxClaimsPerAccount() external view override returns (uint256) {
        return poolData.maxClaimsPerAccount;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function setMaxQuantityPerClaim(uint256 maxQty) external override onlyController {
        poolData.maxQuantityPerClaim = maxQty;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function setMaxClaimsPerAccount(uint256 maxCPA) external override onlyController {
        poolData.maxClaimsPerAccount = maxCPA;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function allowPurchase() external view override returns (bool) {
        return poolData.allowPurchase;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function setAllowPurchase(bool allow) external override onlyController {
        poolData.allowPurchase = allow;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function priceIncrementType() external view override returns (PriceIncrementType) {
        return poolData.priceIncrementType;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function setPriceIncrementType(PriceIncrementType incrementType) external override onlyController {
        poolData.priceIncrementType = incrementType;
    }

    /**
     * @dev number of claims made thus far
     */
    function claimedCount() external view override returns (uint256) {
        return poolData.nextClaimIdVal;
    }

    /**
     * @dev the number of gems minted in this
     */
    function mintedCount() external view override returns (uint256) {
        return poolData.nextGemIdVal;
    }

    /**
     * @dev the number of gems minted in this
     */
    function totalStakedEth() external view override returns (uint256) {
        return poolData.totalStakedEth;
    }

    /**
     * @dev get token type of hash - 1 is for claim, 2 is for gem
     */
    function tokenType(uint256 tokenHash) external view override returns (uint8) {
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
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function allTokenHashesLength() external view override returns (uint256) {
        return poolData.tokenHashes.length;
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function allTokenHashes(uint256 ndx) external view override returns (uint256) {
        return poolData.tokenHashes[ndx];
    }

    /**
     * @dev the external version of the above
     */
    function nextClaimHash() external view override returns (uint256) {
        return poolData.nextClaimHash();
    }

    /**
     * @dev the external version of the above
     */
    function nextGemHash() external view override returns (uint256) {
        return poolData.nextGemHash();
    }

    /**
     * @dev the external version of the above
     */
    function nextClaimId() external view override returns (uint256) {
        return poolData.nextClaimIdVal;
    }

    /**
     * @dev the external version of the above
     */
    function nextGemId() external view override returns (uint256) {
        return poolData.nextGemIdVal;
    }

    /**
     * @dev the external version of the above
     */
    function allowedTokensLength() external view override returns (uint256) {
        return poolData.allowedTokens.count();
    }

    /**
     * @dev the external version of the above
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
     * @dev the external version of the above
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
    function setVisible(bool visible) external override onlyController {
        poolData.visible = visible;
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
    function setCategory(uint256 category) external override onlyController {
        poolData.category = category;
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
        address token,
        address pool,
        uint8 inputType,
        uint256 tid,
        uint256 minAmount,
        bool burn
    ) external override onlyController {
        poolData.addInputRequirement(token, pool, inputType, tid, minAmount, burn);
    }

    /**
     * @dev add an input requirement for this token
     */
    function updateInputRequirement(
        uint256 ndx,
        address token,
        address pool,
        uint8 inputType,
        uint256 tid,
        uint256 minAmount,
        bool burn
    ) external override onlyController {
        poolData.updateInputRequirement(ndx, token, pool, inputType, tid, minAmount, burn);
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
            uint8,
            uint256,
            uint256,
            bool
        )
    {
        return poolData.allInputRequirements(ndx);
    }

    /**
     * @dev add an allowed token source
     */
    function addAllowedTokenSource(address allowedToken) external override {
        if(!poolData.allowedTokenSources.exists(allowedToken)) {
            poolData.allowedTokenSources.insert(allowedToken);
        }
    }

    /**
     * @dev remove an allowed token source
     */
    function removeAllowedTokenSource(address allowedToken) external override {
        if(poolData.allowedTokenSources.exists(allowedToken)) {
            poolData.allowedTokenSources.remove(allowedToken);
        }
    }

    /**
     * @dev returns an array of all allowed token sources
     */
    function allowedTokenSources() external override returns (address[] memory) {
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

    function token(uint256 tokenHash) external view override returns (uint8 tokenType, uint256 tokenId, address tokenSource) {
        tokenType = poolData.tokenTypes[tokenHash];
        tokenId = poolData.tokenIds[tokenHash];
        tokenSource = poolData.tokenSources[tokenHash];
    }

    function addLegacyToken(
        address token,
        uint8 tokenType,
        uint256 tokenHash,
        uint256 tokenId,
        address recipient,
        uint256 qty
    ) external override onlyController {
        require(tokenType > 0, "INVALID_TOKENTYPE");
        require(tokenHash > 0, "INVALID_TOKENHASH");
        require(token > address(0), "INVALID_TOKEN");
        require(recipient > address(0), "INVALID_RECIPIENT");
        require(poolData.allowedTokenSources.exists(token) == true, "INVALID_TOKENSOURCE");
        require(qty > 0, "INVALID_QUANTIY");

        INFTGemMultiToken(poolData.multitoken).mint(recipient, tokenHash, qty);
        INFTGemMultiToken(poolData.multitoken).setTokenData(tokenHash, tokenType, address(this));
        poolData.tokenTypes[tokenHash] = tokenType;
        poolData.tokenIds[tokenHash] = tokenId;
        poolData.tokenSources[tokenHash] = token;
    }

    function setToken(
        uint256 tokenHash,
        uint8 tokenType,
        uint256 tokenId
    ) external override onlyController {
        poolData.tokenTypes[tokenHash] = tokenType;
        poolData.tokenIds[tokenHash] = tokenId;
    }

    function setNextIds(uint256 nextClaimId, uint256 nextGemId) external override onlyController {
        poolData.nextClaimIdVal = nextClaimId;
        poolData.nextGemIdVal = nextGemId;
    }
}
