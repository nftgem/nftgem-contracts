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
            poolData.controllers[msg.sender] == true || address(this) == msg.sender,
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
    function setVisible(bool visible) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
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
    function setCategory(uint256 category) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
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
    function setDescription(string memory desc) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
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
    function setValidateErc20(bool) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
        poolData.validateerc20 = true;
    }

    /**
     * @dev get validate erc20 token against AMM
     */
    function validateErc20() external view override returns (bool) {
        return poolData.validateerc20;
    }

    /**
     * @dev Transfer a quantity of input reqs from to
     */
    function transferInputReqsFrom(
        uint256 claimHash,
        address from,
        address to,
        uint256 quantity
    ) internal {
        poolData.transferInputReqsFrom(claimHash, from, to, quantity, from == address(this));
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

    function token(uint256 tokenHash) external view override returns (uint8 tokenType, uint256 tokenId) {
        tokenType = poolData.tokenTypes[tokenHash];
        tokenId = poolData.tokenIds[tokenHash];
    }
}
