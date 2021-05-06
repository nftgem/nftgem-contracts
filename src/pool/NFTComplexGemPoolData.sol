// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/AddressSet.sol";
import "../libs/SafeMath.sol";

import "./ComplexPoolLib.sol";

import "../interfaces/INFTGemPoolData.sol";
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

    constructor() {}

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
    function addAllowedToken(address token) external override {
        poolData.allowedTokens.insert(token);
    }

    /**
     * @dev add ad allowed token to the pool
     */
    function removeAllowedToken(address token) external override {
        poolData.allowedTokens.remove(token);
    }

    /**
     * @dev the external version of the above
     */
    function isTokenAllowed(address token) external view override returns (bool) {
        return poolData.allowedTokens.exists(token);
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
    ) external override {
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
    ) external override {
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
}
