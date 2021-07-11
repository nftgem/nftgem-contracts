// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libs/AddressSet.sol";

import "./ComplexPoolLib.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/INFTGemPoolData.sol";

contract NFTComplexGemPoolData is INFTComplexGemPoolData {
    using AddressSet for AddressSet.Set;
    using ComplexPoolLib for ComplexPoolLib.ComplexPoolData;

    ComplexPoolLib.ComplexPoolData internal poolData;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            poolData.controllers[msg.sender] == true ||
                msg.sender == poolData.governor ||
                address(this) == msg.sender,
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
    function setTokenHashes(uint256[] memory _tokenHashes)
        external
        override
        onlyController
    {
        poolData.tokenHashes = _tokenHashes;
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
    function setMaxQuantityPerClaim(uint256 _maxQuantityPerClaim)
        external
        override
        onlyController
    {
        poolData.maxQuantityPerClaim = _maxQuantityPerClaim;
    }

    /**
     * @dev update max claims that can be made on this NFT
     */
    function setMaxClaimsPerAccount(uint256 _maxClaimsPerAccount)
        external
        override
        onlyController
    {
        poolData.maxClaimsPerAccount = _maxClaimsPerAccount;
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
    function setAllowPurchase(bool _allowPurchase)
        external
        override
        onlyController
    {
        poolData.allowPurchase = _allowPurchase;
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
    function setEnabled(bool _enabled) external override onlyController {
        poolData.enabled = _enabled;
    }

    /**
     * @dev return the appreciation curve of this pool.
     */
    function priceIncrementType()
        external
        view
        override
        returns (PriceIncrementType)
    {
        return poolData.priceIncrementType;
    }

    /**
     * @dev set the appreciation curve of this pool.
     */
    function setPriceIncrementType(PriceIncrementType _incrementType)
        external
        override
        onlyController
    {
        poolData.priceIncrementType = _incrementType;
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
    function tokenType(uint256 _tokenHash)
        external
        view
        override
        returns (INFTGemMultiToken.TokenType)
    {
        return poolData.tokenTypes[_tokenHash];
    }

    /**
     * @dev get the claim hash of the gem
     */
    function gemClaimHash(uint256 _claimHash)
        external
        view
        override
        returns (uint256)
    {
        return poolData.gemClaims[_claimHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function tokenId(uint256 _tokenHash)
        external
        view
        override
        returns (uint256)
    {
        return poolData.tokenIds[_tokenHash];
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
    function allTokenHashes(uint256 ndx)
        external
        view
        override
        returns (uint256)
    {
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
    function allowedTokens(uint256 _index)
        external
        view
        override
        returns (address)
    {
        return poolData.allowedTokens.keyAtIndex(_index);
    }

    /**
     * @dev add an allowed token to the pool
     */
    function addAllowedToken(address _tokenAddress)
        external
        override
        onlyController
    {
        poolData.allowedTokens.insert(_tokenAddress);
    }

    /**
     * @dev add an allowed token to the pool
     */
    function removeAllowedToken(address _tokenAddress)
        external
        override
        onlyController
    {
        poolData.allowedTokens.remove(_tokenAddress);
    }

    /**
     * @dev is the token in the allowed tokens list
     */
    function isTokenAllowed(address _tokenAddress)
        external
        view
        override
        returns (bool)
    {
        return poolData.allowedTokens.exists(_tokenAddress);
    }

    /**
     * @dev the claim amount for the given claim id
     */
    function claimAmount(uint256 _claimHash)
        external
        view
        override
        returns (uint256)
    {
        return poolData.claimAmount(_claimHash);
    }

    /**
     * @dev the claim quantity (count of gems staked) for the given claim id
     */
    function claimQuantity(uint256 _claimHash)
        external
        view
        override
        returns (uint256)
    {
        return poolData.claimQuantity(_claimHash);
    }

    /**
     * @dev the lock time for this claim. once past lock time a gema is minted
     */
    function claimUnlockTime(uint256 _claimHash)
        external
        view
        override
        returns (uint256)
    {
        return poolData.claimUnlockTime(_claimHash);
    }

    /**
     * @dev claim token amount if paid using erc20
     */
    function claimTokenAmount(uint256 _claimHash)
        external
        view
        override
        returns (uint256)
    {
        return poolData.claimTokenAmount(_claimHash);
    }

    /**
     * @dev the staked token if staking with erc20
     */
    function stakedToken(uint256 _claimHash)
        external
        view
        override
        returns (address)
    {
        return poolData.stakedToken(_claimHash);
    }

    /**
     * @dev set market visibility
     */
    function setVisible(bool _visible) external override onlyController {
        poolData.visible = _visible;
    }

    /**
     * @dev set market visibility
     */
    function visible() external view override returns (bool) {
        return poolData.visible;
    }

    /**
     * @dev set category category
     */
    function setCategory(uint256 _category) external override onlyController {
        poolData.category = _category;
    }

    /**
     * @dev get market category
     */
    function category() external view override returns (uint256) {
        return poolData.category;
    }

    /**
     * @dev set description
     */
    function setDescription(string memory desc)
        external
        override
        onlyController
    {
        poolData.description = desc;
    }

    /**
     * @dev get description
     */
    function description() external view override returns (string memory) {
        return poolData.description;
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
        address _tokenAddress,
        address _poolAddress,
        INFTComplexGemPool.RequirementType _inputType,
        uint256 _tokenId,
        uint256 _minAmount,
        bool _takeCustody,
        bool _burn
    ) external override {
        // require(_tokenAddress != address(0), "INVALID_TOKEN");
        // require(
        //     _inputType == INFTComplexGemPool.RequirementType.ERC20 ||
        //         _inputType == INFTComplexGemPool.RequirementType.ERC1155 ||
        //         _inputType == INFTComplexGemPool.RequirementType.POOL,
        //     "INVALID_INPUTTYPE"
        // );
        // require(
        //     (_inputType == INFTComplexGemPool.RequirementType.POOL &&
        //         _poolAddress != address(0)) ||
        //         _inputType != INFTComplexGemPool.RequirementType.POOL,
        //     "INVALID_POOL"
        // );
        // require(
        //     (_inputType == INFTComplexGemPool.RequirementType.ERC20 &&
        //         _tokenId == 0) ||
        //         _inputType == INFTComplexGemPool.RequirementType.ERC1155 ||
        //         (_inputType == INFTComplexGemPool.RequirementType.POOL &&
        //             _tokenId == 0),
        //     "INVALID_TOKENID"
        // );
        // require(_minAmount != 0, "ZERO_AMOUNT");
        // require(!(!_takeCustody && _burn), "INVALID_TOKENSTATE");
        // poolData.inputRequirements.push(
        //     INFTComplexGemPoolData.InputRequirement(
        //         _tokenAddress,
        //         _poolAddress,
        //         _inputType,
        //         _tokenId,
        //         _minAmount,
        //         _takeCustody,
        //         _burn
        //     )
        // );
    }

    /**
     * @dev add an input requirement for this token
     */
    function updateInputRequirement(
        uint256 _index,
        address _tokenAddress,
        address _poolAddress,
        INFTComplexGemPool.RequirementType _inputType,
        uint256 _tokenId,
        uint256 _minAmount,
        bool _takeCustody,
        bool _burn
    ) external override {
        poolData.updateInputRequirement(
            _index,
            _tokenAddress,
            _poolAddress,
            _inputType,
            _tokenId,
            _minAmount,
            _takeCustody,
            _burn
        );
    }

    /**
     * @dev all Input Requirements Length
     */
    function allInputRequirementsLength()
        external
        view
        override
        returns (uint256)
    {
        return poolData.allInputRequirementsLength();
    }

    /**
     * @dev all Input Requirements at element
     */
    function allInputRequirements(uint256 _index)
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
        return poolData.allInputRequirements(_index);
    }

    /**
     * @dev add an allowed token source
     */
    function addAllowedTokenSource(address _allowedToken) external override {
        if (!poolData.allowedTokenSources.exists(_allowedToken)) {
            poolData.allowedTokenSources.insert(_allowedToken);
        }
    }

    /**
     * @dev remove an allowed token source
     */
    function removeAllowedTokenSource(address _allowedToken) external override {
        if (poolData.allowedTokenSources.exists(_allowedToken)) {
            poolData.allowedTokenSources.remove(_allowedToken);
        }
    }

    /**
     * @dev returns an array of all allowed token sources
     */
    function allowedTokenSources()
        external
        view
        override
        returns (address[] memory)
    {
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
            string memory,
            string memory,
            string memory,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            poolData.symbol,
            poolData.name,
            poolData.description,
            poolData.category,
            poolData.ethPrice,
            poolData.minTime,
            poolData.maxTime,
            poolData.diffstep,
            poolData.maxClaims,
            poolData.maxQuantityPerClaim,
            poolData.maxClaimsPerAccount
        );
    }

    /**
     * @dev these stats reflect the current pool state
     */
    function stats()
        external
        view
        override
        returns (
            bool,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            poolData.visible,
            poolData.nextClaimIdVal,
            poolData.nextGemIdVal,
            poolData.totalStakedEth,
            poolData.nextClaimHash(),
            poolData.nextGemHash(),
            poolData.nextClaimIdVal,
            poolData.nextGemIdVal
        );
    }

    /**
     * @dev return the claim details for the given claim hash
     */
    function claim(uint256 claimHash)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256
        )
    {
        return (
            poolData.claimAmount(claimHash),
            poolData.claimQuantity(claimHash),
            poolData.claimUnlockTime(claimHash),
            poolData.claimTokenAmount(claimHash),
            poolData.stakedToken(claimHash),
            poolData.nextClaimIdVal
        );
    }

    /**
     * @dev return the token data for the given hash
     */
    function token(uint256 _tokenHash)
        external
        view
        override
        returns (
            INFTGemMultiToken.TokenType,
            uint256,
            address
        )
    {
        return (
            poolData.tokenTypes[_tokenHash],
            poolData.tokenIds[_tokenHash],
            poolData.tokenSources[_tokenHash]
        );
    }

    /**
     * @dev import the legacy gem
     */
    function importLegacyGem(
        address _poolAddress,
        address _legacyToken,
        uint256 _tokenHash,
        address _recipient
    ) external override {
        // this method is callable by anyone - this is used to import historical
        // gems into the new contracts. A gem can only be imported in once
        // per source
        require(_tokenHash > 0, "INVALID_TOKENHASH");
        require(_poolAddress > address(0), "INVALID_POOL");
        require(_legacyToken > address(0), "INVALID_TOKEN");
        require(_recipient > address(0), "INVALID_RECIPIENT");
        require(
            poolData.allowedTokenSources.exists(_legacyToken) == true,
            "INVALID_TOKENSOURCE"
        );
        require(
            poolData.importedLegacyToken[_tokenHash] == false,
            "ALREADY_IMPORTED"
        );

        bytes32 importedSymHash = keccak256(
            abi.encodePacked(INFTGemPoolData(_poolAddress).symbol())
        );
        bytes32 poolSymHash = keccak256(abi.encodePacked(poolData.symbol));
        require(importedSymHash == poolSymHash, "INVALID_POOLHASH");

        INFTGemMultiToken.TokenType importTokenType = INFTGemPoolData(
            _poolAddress
        ).tokenType(_tokenHash);
        require(
            importTokenType == INFTGemMultiToken.TokenType.GEM,
            "INVALID_TOKENTYPE"
        );

        uint256 quantity = IERC1155(_legacyToken).balanceOf(
            _recipient,
            _tokenHash
        );
        uint256 importTokenId = INFTGemPoolData(_poolAddress).tokenId(
            _tokenHash
        );

        if (quantity > 0) {
            INFTGemMultiToken(poolData.multitoken).mint(
                _recipient,
                _tokenHash,
                quantity
            );
            INFTGemMultiToken(poolData.multitoken).setTokenData(
                _tokenHash,
                INFTGemMultiToken.TokenType.GEM,
                address(this)
            );

            poolData.tokenTypes[_tokenHash] = INFTGemMultiToken.TokenType.GEM;
            poolData.tokenIds[_tokenHash] = importTokenId;
            poolData.tokenSources[_tokenHash] = _legacyToken;
            poolData.importedLegacyToken[_tokenHash] = true;

            emit NFTGemImported(
                msg.sender,
                address(this),
                _poolAddress,
                _legacyToken,
                _tokenHash,
                quantity
            );
        }
    }

    /**
     * @dev returns if legacy gem with given hash is imported
     */
    function isLegacyGemImported(uint256 _tokenhash)
        external
        view
        override
        returns (bool)
    {
        return poolData.importedLegacyToken[_tokenhash];
    }

    /**
     * @dev set the next claim and gem ids
     */
    function setNextIds(uint256 _nextClaimId, uint256 _nextGemId)
        external
        override
        onlyController
    {
        poolData.nextClaimIdVal = _nextClaimId;
        poolData.nextGemIdVal = _nextGemId;
    }
}
