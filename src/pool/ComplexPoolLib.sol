// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/ISwapQueryHelper.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemGovernor.sol";
import "../interfaces/INFTComplexGemPool.sol";
import "../interfaces/INFTGemFeeManager.sol";

import "../libs/AddressSet.sol";

library ComplexPoolLib {
    using AddressSet for AddressSet.Set;
    address private constant WFTM = 0x21be370D5312f44cB42ce377BC9b8a0cEF1A4C83;
    /**
     * @dev Event generated when an NFT claim is created using base currency
     */
    event NFTGemClaimCreated(
        address indexed account,
        address indexed pool,
        uint256 indexed claimHash,
        uint256 length,
        uint256 quantity,
        uint256 amountPaid
    );

    /**
     * @dev Event generated when an NFT claim is created using ERC20 tokens
     */
    event NFTGemERC20ClaimCreated(
        address indexed account,
        address indexed pool,
        uint256 indexed claimHash,
        uint256 length,
        address token,
        uint256 quantity,
        uint256 conversionRate
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemClaimRedeemed(
        address indexed account,
        address indexed pool,
        uint256 indexed claimHash,
        uint256 amountPaid,
        uint256 quantity,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when an NFT erc20 claim is redeemed
     */
    event NFTGemERC20ClaimRedeemed(
        address indexed account,
        address indexed pool,
        uint256 indexed claimHash,
        address token,
        uint256 ethPrice,
        uint256 tokenAmount,
        uint256 quantity,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when a gem is created
     */
    event NFTGemCreated(
        address account,
        address pool,
        uint256 claimHash,
        uint256 gemHash,
        uint256 quantity
    );

    /**
     * @dev data describes complex pool
     */
    struct ComplexPoolData {
        // governor and multitoken target
        address pool;
        address multitoken;
        address governor;
        address feeTracker;
        address swapHelper;
        uint256 category;
        bool visible;
        // it all starts with a symbol and a nams
        string symbol;
        string name;
        string description;
        // magic economy numbers
        uint256 ethPrice;
        uint256 minTime;
        uint256 maxTime;
        uint256 diffstep;
        uint256 maxClaims;
        uint256 maxQuantityPerClaim;
        uint256 maxClaimsPerAccount;
        bool validateerc20;
        bool allowPurchase;
        bool enabled;
        INFTComplexGemPoolData.PriceIncrementType priceIncrementType;
        mapping(uint256 => INFTGemMultiToken.TokenType) tokenTypes;
        mapping(uint256 => uint256) tokenIds;
        mapping(uint256 => address) tokenSources;
        AddressSet.Set allowedTokenSources;
        uint256[] tokenHashes;
        // next ids of things
        uint256 nextGemIdVal;
        uint256 nextClaimIdVal;
        uint256 totalStakedEth;
        // records claim timestamp / ETH value / ERC token and amount sent
        mapping(uint256 => uint256) claimLockTimestamps;
        mapping(uint256 => address) claimLockToken;
        mapping(uint256 => uint256) claimAmountPaid;
        mapping(uint256 => uint256) claimQuant;
        mapping(uint256 => uint256) claimTokenAmountPaid;
        mapping(uint256 => mapping(address => uint256)) importedLegacyToken;
        // input NFTs storage
        mapping(uint256 => uint256) gemClaims;
        mapping(uint256 => uint256[]) claimIds;
        mapping(uint256 => uint256[]) claimQuantities;
        mapping(address => bool) controllers;
        mapping(address => uint256) claimsMade;
        INFTComplexGemPoolData.InputRequirement[] inputRequirements;
        AddressSet.Set allowedTokens;
    }

    function checkGemRequirement(
        ComplexPoolData storage self,
        uint256 _inputIndex,
        address _holderAddress,
        uint256 _quantity
    ) internal view returns (address) {
        address gemtoken;
        int256 required = int256(
            self.inputRequirements[_inputIndex].minVal * _quantity
        );
        uint256[] memory hashes = INFTGemMultiToken(
            self.inputRequirements[_inputIndex].token
        ).heldTokens(_holderAddress);
        for (
            uint256 _hashIndex = 0;
            _hashIndex < hashes.length;
            _hashIndex += 1
        ) {
            uint256 hashAt = hashes[_hashIndex];
            if (
                INFTComplexGemPoolData(self.inputRequirements[_inputIndex].pool)
                .tokenType(hashAt) == INFTGemMultiToken.TokenType.GEM
            ) {
                gemtoken = self.inputRequirements[_inputIndex].token;
                uint256 balance = IERC1155(
                    self.inputRequirements[_inputIndex].token
                ).balanceOf(_holderAddress, hashAt);
                if (balance > uint256(required)) {
                    balance = uint256(required);
                }
                if (balance == 0) {
                    continue;
                }
                required = required - int256(balance);
            }
            if (
                required == 0 &&
                self.inputRequirements[_inputIndex].exactAmount == false
            ) {
                break;
            }
            if (required < 0) {
                require(required == 0, "EXACT_AMOUNT_REQUIRED");
            }
        }
        require(required == 0, "UNMET_GEM_REQUIREMENT");
        return gemtoken;
    }

    /**
     * @dev checks to see that account owns all the pool requirements needed to mint at least the given quantity of NFT
     */
    function requireInputReqs(
        ComplexPoolData storage self,
        address _holderAddress,
        uint256 _quantity
    ) public view {
        for (
            uint256 _inputIndex = 0;
            _inputIndex < self.inputRequirements.length;
            _inputIndex += 1
        ) {
            if (
                self.inputRequirements[_inputIndex].inputType ==
                INFTComplexGemPool.RequirementType.ERC20
            ) {
                require(
                    IERC20(self.inputRequirements[_inputIndex].token).balanceOf(
                        _holderAddress
                    ) >=
                        self.inputRequirements[_inputIndex].minVal *
                            (_quantity),
                    "UNMET_ERC20_REQUIREMENT"
                );
            } else if (
                self.inputRequirements[_inputIndex].inputType ==
                INFTComplexGemPool.RequirementType.ERC1155
            ) {
                require(
                    IERC1155(self.inputRequirements[_inputIndex].token)
                    .balanceOf(
                        _holderAddress,
                        self.inputRequirements[_inputIndex].tokenId
                    ) >=
                        self.inputRequirements[_inputIndex].minVal *
                            (_quantity),
                    "UNMET_ERC1155_REQUIREMENT"
                );
            } else if (
                self.inputRequirements[_inputIndex].inputType ==
                INFTComplexGemPool.RequirementType.POOL
            ) {
                checkGemRequirement(
                    self,
                    _inputIndex,
                    _holderAddress,
                    _quantity
                );
            }
        }
    }

    /**
     * @dev Transfer a quantity of input reqs from to
     */
    function takeInputReqsFrom(
        ComplexPoolData storage self,
        uint256 _claimHash,
        address _fromAddress,
        uint256 _quantity
    ) internal {
        address gemtoken;
        for (
            uint256 _inputIndex = 0;
            _inputIndex < self.inputRequirements.length;
            _inputIndex += 1
        ) {
            if (!self.inputRequirements[_inputIndex].takeCustody) {
                continue;
            }
            if (
                self.inputRequirements[_inputIndex].inputType ==
                INFTComplexGemPool.RequirementType.ERC20
            ) {
                IERC20 token = IERC20(
                    self.inputRequirements[_inputIndex].token
                );
                token.transferFrom(
                    _fromAddress,
                    self.pool,
                    self.inputRequirements[_inputIndex].minVal * (_quantity)
                );
            } else if (
                self.inputRequirements[_inputIndex].inputType ==
                INFTComplexGemPool.RequirementType.ERC1155
            ) {
                IERC1155 token = IERC1155(
                    self.inputRequirements[_inputIndex].token
                );
                token.safeTransferFrom(
                    _fromAddress,
                    self.pool,
                    self.inputRequirements[_inputIndex].tokenId,
                    self.inputRequirements[_inputIndex].minVal * (_quantity),
                    ""
                );
            } else if (
                self.inputRequirements[_inputIndex].inputType ==
                INFTComplexGemPool.RequirementType.POOL
            ) {
                gemtoken = checkGemRequirement(
                    self,
                    _inputIndex,
                    _fromAddress,
                    _quantity
                );
            }
        }

        if (self.claimIds[_claimHash].length > 0 && gemtoken != address(0)) {
            IERC1155(gemtoken).safeBatchTransferFrom(
                _fromAddress,
                self.pool,
                self.claimIds[_claimHash],
                self.claimQuantities[_claimHash],
                ""
            );
        }
    }

    /**
     * @dev Return the returnable input requirements for claimhash to account
     */
    function returnInputReqsTo(
        ComplexPoolData storage self,
        uint256 _claimHash,
        address _toAddress,
        uint256 _quantity
    ) internal {
        address gemtoken;
        for (uint256 i = 0; i < self.inputRequirements.length; i++) {
            if (
                self.inputRequirements[i].inputType ==
                INFTComplexGemPool.RequirementType.ERC20 &&
                self.inputRequirements[i].burn == false &&
                self.inputRequirements[i].takeCustody == true
            ) {
                IERC20 token = IERC20(self.inputRequirements[i].token);
                token.transferFrom(
                    self.pool,
                    _toAddress,
                    self.inputRequirements[i].minVal * (_quantity)
                );
            } else if (
                self.inputRequirements[i].inputType ==
                INFTComplexGemPool.RequirementType.ERC1155 &&
                self.inputRequirements[i].burn == false &&
                self.inputRequirements[i].takeCustody == true
            ) {
                IERC1155 token = IERC1155(self.inputRequirements[i].token);
                token.safeTransferFrom(
                    self.pool,
                    _toAddress,
                    self.inputRequirements[i].tokenId,
                    self.inputRequirements[i].minVal * (_quantity),
                    ""
                );
            } else if (
                self.inputRequirements[i].inputType ==
                INFTComplexGemPool.RequirementType.POOL &&
                self.inputRequirements[i].burn == false &&
                self.inputRequirements[i].takeCustody == true
            ) {
                gemtoken = self.inputRequirements[i].token;
            }
        }
        if (self.claimIds[_claimHash].length > 0 && gemtoken != address(0)) {
            IERC1155(gemtoken).safeBatchTransferFrom(
                self.pool,
                _toAddress,
                self.claimIds[_claimHash],
                self.claimQuantities[_claimHash],
                ""
            );
        }
    }

    /**
     * @dev add an input requirement for this token
     */
    function addInputRequirement(
        ComplexPoolData storage self,
        address token,
        address pool,
        INFTComplexGemPool.RequirementType inputType,
        uint256 tokenId,
        uint256 minAmount,
        bool takeCustody,
        bool burn,
        bool exactAmount
    ) public {
        require(token != address(0), "INVALID_TOKEN");
        require(
            inputType == INFTComplexGemPool.RequirementType.ERC20 ||
                inputType == INFTComplexGemPool.RequirementType.ERC1155 ||
                inputType == INFTComplexGemPool.RequirementType.POOL,
            "INVALID_INPUTTYPE"
        );
        require(
            (inputType == INFTComplexGemPool.RequirementType.POOL &&
                pool != address(0)) ||
                inputType != INFTComplexGemPool.RequirementType.POOL,
            "INVALID_POOL"
        );
        require(
            (inputType == INFTComplexGemPool.RequirementType.ERC20 &&
                tokenId == 0) ||
                inputType == INFTComplexGemPool.RequirementType.ERC1155 ||
                (inputType == INFTComplexGemPool.RequirementType.POOL &&
                    tokenId == 0),
            "INVALID_TOKENID"
        );
        require(minAmount != 0, "ZERO_AMOUNT");
        require(!(!takeCustody && burn), "INVALID_TOKENSTATE");
        self.inputRequirements.push(
            INFTComplexGemPoolData.InputRequirement(
                token,
                pool,
                inputType,
                tokenId,
                minAmount,
                takeCustody,
                burn,
                exactAmount
            )
        );
    }

    /**
     * @dev update input requirement at index
     */
    function updateInputRequirement(
        ComplexPoolData storage self,
        uint256 _index,
        address _tokenAddress,
        address _poolAddress,
        INFTComplexGemPool.RequirementType _inputRequirementType,
        uint256 _tokenId,
        uint256 _minAmount,
        bool _takeCustody,
        bool _burn,
        bool _exactAmount
    ) public {
        require(_index < self.inputRequirements.length, "OUT_OF_RANGE");
        require(_tokenAddress != address(0), "INVALID_TOKEN");
        require(
            _inputRequirementType == INFTComplexGemPool.RequirementType.ERC20 ||
                _inputRequirementType ==
                INFTComplexGemPool.RequirementType.ERC1155 ||
                _inputRequirementType ==
                INFTComplexGemPool.RequirementType.POOL,
            "INVALID_INPUTTYPE"
        );
        require(
            (_inputRequirementType == INFTComplexGemPool.RequirementType.POOL &&
                _poolAddress != address(0)) ||
                _inputRequirementType !=
                INFTComplexGemPool.RequirementType.POOL,
            "INVALID_POOL"
        );
        require(
            (_inputRequirementType ==
                INFTComplexGemPool.RequirementType.ERC20 &&
                _tokenId == 0) ||
                _inputRequirementType ==
                INFTComplexGemPool.RequirementType.ERC1155 ||
                (_inputRequirementType ==
                    INFTComplexGemPool.RequirementType.POOL &&
                    _tokenId == 0),
            "INVALID_TOKENID"
        );
        require(_minAmount != 0, "ZERO_AMOUNT");
        require(!(!_takeCustody && _burn), "INVALID_TOKENSTATE");
        self.inputRequirements[_index] = INFTComplexGemPoolData
        .InputRequirement(
            _tokenAddress,
            _poolAddress,
            _inputRequirementType,
            _tokenId,
            _minAmount,
            _takeCustody,
            _burn,
            _exactAmount
        );
    }

    /**
     * @dev count of input requirements
     */
    function allInputRequirementsLength(ComplexPoolData storage self)
        public
        view
        returns (uint256)
    {
        return self.inputRequirements.length;
    }

    /**
     * @dev input requirements at index
     */
    function allInputRequirements(ComplexPoolData storage self, uint256 _index)
        public
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
        )
    {
        require(_index < self.inputRequirements.length, "OUT_OF_RANGE");
        INFTComplexGemPoolData.InputRequirement memory req = self
        .inputRequirements[_index];
        return (
            req.token,
            req.pool,
            req.inputType,
            req.tokenId,
            req.minVal,
            req.takeCustody,
            req.burn,
            req.exactAmount
        );
    }

    /**
     * @dev attempt to create a claim using the given timeframe with count
     */
    function createClaims(
        ComplexPoolData storage self,
        uint256 _timeframe,
        uint256 _count
    ) public {
        // enabled
        require(self.enabled == true, "DISABLED");
        // minimum timeframe
        require(_timeframe >= self.minTime, "TIMEFRAME_TOO_SHORT");
        // no ETH
        require(msg.value != 0, "ZERO_BALANCE");
        // zero qty
        require(_count != 0, "ZERO_QUANTITY");
        // maximum timeframe
        require(
            (self.maxTime != 0 && _timeframe <= self.maxTime) ||
                self.maxTime == 0,
            "TIMEFRAME_TOO_LONG"
        );
        // max quantity per claim
        require(
            (self.maxQuantityPerClaim != 0 &&
                _count <= self.maxQuantityPerClaim) ||
                self.maxQuantityPerClaim == 0,
            "MAX_QUANTITY_EXCEEDED"
        );
        require(
            (self.maxClaimsPerAccount != 0 &&
                self.claimsMade[msg.sender] < self.maxClaimsPerAccount) ||
                self.maxClaimsPerAccount == 0,
            "MAX_QUANTITY_EXCEEDED"
        );

        uint256 adjustedBalance = msg.value / (_count);
        // cost given this timeframe

        uint256 cost = (self.ethPrice * (self.minTime)) / (_timeframe);
        require(adjustedBalance >= cost, "INSUFFICIENT_ETH");

        // get the nest claim hash, revert if no more claims
        uint256 claimHash = nextClaimHash(self);
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // require the user to have the input requirements
        requireInputReqs(self, msg.sender, _count);

        // mint the new claim to the caller's address
        INFTGemMultiToken(self.multitoken).mint(msg.sender, claimHash, 1);
        INFTGemMultiToken(self.multitoken).setTokenData(
            claimHash,
            INFTGemMultiToken.TokenType.CLAIM,
            address(this)
        );
        addToken(self, claimHash, INFTGemMultiToken.TokenType.CLAIM);

        // record the claim unlock time and cost paid for this claim
        uint256 claimUnlockTimestamp = block.timestamp + (_timeframe);
        self.claimLockTimestamps[claimHash] = claimUnlockTimestamp;
        self.claimAmountPaid[claimHash] = cost * (_count);
        self.claimQuant[claimHash] = _count;
        self.claimsMade[msg.sender] = self.claimsMade[msg.sender] + (1);

        // tranasfer NFT input requirements from user to pool
        takeInputReqsFrom(self, claimHash, msg.sender, _count);

        // emit an event about it
        emit NFTGemClaimCreated(
            msg.sender,
            address(self.pool),
            claimHash,
            _timeframe,
            _count,
            cost
        );

        // increase the staked eth balance
        self.totalStakedEth = self.totalStakedEth + (cost * (_count));

        // return the extra to sender
        if (msg.value > cost * (_count)) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - (cost * (_count))
            }("");
            require(success, "REFUND_FAILED");
        }
    }

    function getPoolFee(ComplexPoolData storage self, address tokenUsed)
        internal
        view
        returns (uint256)
    {
        // get the fee for this pool if it exists
        uint256 poolDivFeeHash = uint256(
            keccak256(abi.encodePacked("pool_fee", address(self.pool)))
        );
        uint256 poolFee = INFTGemFeeManager(self.feeTracker).fee(
            poolDivFeeHash
        );
        // get the pool fee for this token if it exists
        uint256 poolTokenFeeHash = uint256(
            keccak256(abi.encodePacked("pool_fee", address(tokenUsed)))
        );
        uint256 poolTokenFee = INFTGemFeeManager(self.feeTracker).fee(
            poolTokenFeeHash
        );
        // get the default fee amoutn for this token
        uint256 defaultFeeHash = uint256(
            keccak256(abi.encodePacked("pool_fee"))
        );
        uint256 defaultFee = INFTGemFeeManager(self.feeTracker).fee(
            defaultFeeHash
        );
        defaultFee = defaultFee == 0 ? 2000 : defaultFee;

        // get the fee, preferring the token fee if available
        uint256 feeNum = poolFee != poolTokenFee
            ? (poolTokenFee != 0 ? poolTokenFee : poolFee)
            : poolFee;

        // set the fee to default if it is 0
        return feeNum == 0 ? defaultFee : feeNum;
    }

    function getMinimumLiquidity(
        ComplexPoolData storage self,
        address tokenUsed
    ) internal view returns (uint256) {
        // get the fee for this pool if it exists
        uint256 poolDivFeeHash = uint256(
            keccak256(abi.encodePacked("min_liquidity", address(self.pool)))
        );
        uint256 poolFee = INFTGemFeeManager(self.feeTracker).fee(
            poolDivFeeHash
        );
        // get the pool fee for this token if it exists
        uint256 poolTokenFeeHash = uint256(
            keccak256(abi.encodePacked("min_liquidity", address(tokenUsed)))
        );
        uint256 poolTokenFee = INFTGemFeeManager(self.feeTracker).fee(
            poolTokenFeeHash
        );
        // get the default fee amoutn for this token
        uint256 defaultFeeHash = uint256(
            keccak256(abi.encodePacked("min_liquidity"))
        );
        uint256 defaultFee = INFTGemFeeManager(self.feeTracker).fee(
            defaultFeeHash
        );
        defaultFee = defaultFee == 0 ? 50 : defaultFee;

        // get the fee, preferring the token fee if available
        uint256 feeNum = poolFee != poolTokenFee
            ? (poolTokenFee != 0 ? poolTokenFee : poolFee)
            : poolFee;

        // set the fee to default if it is 0
        return feeNum == 0 ? defaultFee : feeNum;
    }

    /**
     * @dev crate multiple gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function createERC20Claims(
        ComplexPoolData storage self,
        address erc20token,
        uint256 tokenAmount,
        uint256 count
    ) public {
        // enabled
        require(self.enabled == true, "DISABLED");
        // must be a valid address
        require(erc20token != address(0), "INVALID_ERC20_TOKEN");

        // token is allowed
        require(
            (self.allowedTokens.count() > 0 &&
                self.allowedTokens.exists(erc20token)) ||
                self.allowedTokens.count() == 0,
            "TOKEN_DISALLOWED"
        );

        // zero qty
        require(count != 0, "ZERO_QUANTITY");

        // max quantity per claim
        require(
            (self.maxQuantityPerClaim != 0 &&
                count <= self.maxQuantityPerClaim) ||
                self.maxQuantityPerClaim == 0,
            "MAX_QUANTITY_EXCEEDED"
        );
        require(
            (self.maxClaimsPerAccount != 0 &&
                self.claimsMade[msg.sender] < self.maxClaimsPerAccount) ||
                self.maxClaimsPerAccount == 0,
            "MAX_QUANTITY_EXCEEDED"
        );

        // require the user to have the input requirements
        requireInputReqs(self, msg.sender, count);

        // Uniswap pool must exist
        require(
            ISwapQueryHelper(self.swapHelper).hasPool(erc20token) == true,
            "NO_UNISWAP_POOL"
        );

        // must have an amount specified
        require(tokenAmount >= 0, "NO_PAYMENT_INCLUDED");

        // get a quote in ETH for the given token.
        (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        ) = ISwapQueryHelper(self.swapHelper).coinQuote(
            erc20token,
            tokenAmount / (count)
        );

        // TODO: update liquidity multiple from fee manager
        if (self.validateerc20 == true) {
            uint256 minLiquidity = getMinimumLiquidity(self, erc20token);
            // make sure the convertible amount is has reserves > 100x the token
            require(
                ethReserve >= ethereum * minLiquidity * (count),
                "INSUFFICIENT_ETH_LIQUIDITY"
            );

            // make sure the convertible amount is has reserves > 100x the token
            require(
                tokenReserve >= tokenAmount * minLiquidity * (count),
                "INSUFFICIENT_TOKEN_LIQUIDITY"
            );
        }

        // make sure the convertible amount is less than max price
        require(ethereum <= self.ethPrice, "OVERPAYMENT");

        // calculate the maturity time given the converted eth
        uint256 maturityTime = (self.ethPrice * (self.minTime)) / (ethereum);

        // make sure the convertible amount is less than max price
        require(maturityTime >= self.minTime, "INSUFFICIENT_TIME");

        // get the next claim hash, revert if no more claims
        uint256 claimHash = nextClaimHash(self);
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(self.multitoken).mint(msg.sender, claimHash, 1);
        INFTGemMultiToken(self.multitoken).setTokenData(
            claimHash,
            INFTGemMultiToken.TokenType.CLAIM,
            address(this)
        );
        addToken(self, claimHash, INFTGemMultiToken.TokenType.CLAIM);

        // record the claim unlock time and cost paid for this claim
        uint256 claimUnlockTimestamp = block.timestamp + (maturityTime);
        self.claimLockTimestamps[claimHash] = claimUnlockTimestamp;
        self.claimAmountPaid[claimHash] = ethereum;
        self.claimLockToken[claimHash] = erc20token;
        self.claimTokenAmountPaid[claimHash] = tokenAmount;
        self.claimQuant[claimHash] = count;
        self.claimsMade[msg.sender] = self.claimsMade[msg.sender] + (1);

        // tranasfer NFT input requirements from user to pool
        takeInputReqsFrom(self, claimHash, msg.sender, count);

        // increase staked eth amount
        self.totalStakedEth = self.totalStakedEth + (ethereum);

        // emit a message indicating that an erc20 claim has been created
        emit NFTGemERC20ClaimCreated(
            msg.sender,
            address(self.pool),
            claimHash,
            maturityTime,
            erc20token,
            count,
            ethereum
        );

        // transfer the caller's ERC20 tokens into the pool
        IERC20(erc20token).transferFrom(
            msg.sender,
            address(self.pool),
            tokenAmount
        );
    }

    /**
     * @dev collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
     */
    function collectClaim(
        ComplexPoolData storage self,
        uint256 _claimHash,
        bool _requireMature
    ) public {
        // enabled
        require(self.enabled == true, "DISABLED");
        // check the maturity of the claim - only issue gem if mature
        uint256 unlockTime = self.claimLockTimestamps[_claimHash];
        bool isMature = unlockTime < block.timestamp;
        require(
            !_requireMature || (_requireMature && isMature),
            "IMMATURE_CLAIM"
        );
        __collectClaim(self, _claimHash);
    }

    /**
     * @dev collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
     */
    function __collectClaim(ComplexPoolData storage self, uint256 claimHash)
        internal
    {
        // validation checks - disallow if not owner (holds coin with claimHash)
        // or if the unlockTime amd unlockPaid data is in an invalid state
        require(
            IERC1155(self.multitoken).balanceOf(msg.sender, claimHash) == 1,
            "NOT_CLAIM_OWNER"
        );
        uint256 unlockTime = self.claimLockTimestamps[claimHash];
        uint256 unlockPaid = self.claimAmountPaid[claimHash];
        require(unlockTime != 0 && unlockPaid > 0, "INVALID_CLAIM");

        // grab the erc20 token info if there is any
        address tokenUsed = self.claimLockToken[claimHash];
        uint256 unlockTokenPaid = self.claimTokenAmountPaid[claimHash];

        // check the maturity of the claim - only issue gem if mature
        bool isMature = unlockTime < block.timestamp;

        //  burn claim and transfer money back to user
        INFTGemMultiToken(self.multitoken).burn(msg.sender, claimHash, 1);

        // if they used erc20 tokens stake their claim, return their tokens
        if (tokenUsed != address(0)) {
            // calculate fee portion using fee tracker
            uint256 feePortion = 0;
            if (isMature == true) {
                feePortion = unlockTokenPaid / getPoolFee(self, tokenUsed);
            }
            // assess a fee for minting the NFT. Fee is collectec in fee tracker
            IERC20(tokenUsed).transferFrom(
                address(self.pool),
                self.feeTracker,
                feePortion
            );
            // send the principal minus fees to the caller
            IERC20(tokenUsed).transferFrom(
                address(self.pool),
                msg.sender,
                unlockTokenPaid - (feePortion)
            );

            // emit an event that the claim was redeemed for ERC20
            emit NFTGemERC20ClaimRedeemed(
                msg.sender,
                address(self.pool),
                claimHash,
                tokenUsed,
                unlockPaid,
                unlockTokenPaid,
                self.claimQuant[claimHash],
                feePortion
            );
        } else {
            // calculate fee portion using fee tracker
            uint256 feePortion = 0;
            if (isMature == true) {
                feePortion = unlockPaid / getPoolFee(self, address(0));
            }
            // transfer the ETH fee to fee tracker
            payable(self.feeTracker).transfer(feePortion);

            // transfer the ETH back to user
            payable(msg.sender).transfer(unlockPaid - (feePortion));

            // emit an event that the claim was redeemed for ETH
            emit NFTGemClaimRedeemed(
                msg.sender,
                address(self.pool),
                claimHash,
                unlockPaid,
                self.claimQuant[claimHash],
                feePortion
            );
        }

        // tranasfer NFT input requirements from pool to user
        returnInputReqsTo(
            self,
            claimHash,
            msg.sender,
            self.claimQuant[claimHash]
        );

        // deduct the total staked ETH balance of the pool
        self.totalStakedEth = self.totalStakedEth - (unlockPaid);

        // if all this is happening before the unlocktime then we exit
        // without minting a gem because the user is withdrawing early
        if (!isMature) {
            return;
        }

        // get the next gem hash, increase the staking sifficulty
        // for the pool, and mint a gem token back to account
        uint256 nextHash = nextGemHash(self);

        // associate gem and claim
        self.gemClaims[nextHash] = claimHash;

        // mint the gem
        INFTGemMultiToken(self.multitoken).mint(
            msg.sender,
            nextHash,
            self.claimQuant[claimHash]
        );
        addToken(self, nextHash, INFTGemMultiToken.TokenType.GEM);

        // emit an event about a gem getting created
        emit NFTGemCreated(
            msg.sender,
            address(self.pool),
            claimHash,
            nextHash,
            self.claimQuant[claimHash]
        );
    }

    /**
     * @dev purchase gem(s) at the listed pool price
     */
    function purchaseGems(
        ComplexPoolData storage self,
        address sender,
        uint256 value,
        uint256 count
    ) public {
        // enabled
        require(self.enabled == true, "DISABLED");
        // non-zero balance
        require(value != 0, "ZERO_BALANCE");
        // non-zero quantity
        require(count != 0, "ZERO_QUANTITY");
        // sufficient input eth
        uint256 adjustedBalance = value / (count);
        require(adjustedBalance >= self.ethPrice, "INSUFFICIENT_ETH");
        require(self.allowPurchase == true, "PURCHASE_DISALLOWED");

        // get the next gem hash, increase the staking sifficulty
        // for the pool, and mint a gem token back to account
        uint256 nextHash = nextGemHash(self);

        // mint the gem
        INFTGemMultiToken(self.multitoken).mint(sender, nextHash, count);
        addToken(self, nextHash, INFTGemMultiToken.TokenType.GEM);

        // transfer the funds for the gem to the fee tracker
        payable(self.feeTracker).transfer(value);

        // emit an event about a gem getting created
        emit NFTGemCreated(sender, address(self.pool), 0, nextHash, count);
    }

    /**
     * @dev create a token of token hash / token type
     */
    function addToken(
        ComplexPoolData storage self,
        uint256 tokenHash,
        INFTGemMultiToken.TokenType tokenType
    ) public {
        require(
            tokenType == INFTGemMultiToken.TokenType.CLAIM ||
                tokenType == INFTGemMultiToken.TokenType.GEM,
            "INVALID_TOKENTYPE"
        );
        self.tokenHashes.push(tokenHash);
        self.tokenTypes[tokenHash] = tokenType;
        self.tokenIds[tokenHash] = tokenType ==
            INFTGemMultiToken.TokenType.CLAIM
            ? nextClaimId(self)
            : nextGemId(self);
        INFTGemMultiToken(self.multitoken).setTokenData(
            tokenHash,
            tokenType,
            address(this)
        );
        if (tokenType == INFTGemMultiToken.TokenType.GEM) {
            increaseDifficulty(self);
        }
    }

    /**
     * @dev get the next claim id
     */
    function nextClaimId(ComplexPoolData storage self)
        public
        returns (uint256)
    {
        uint256 ncId = self.nextClaimIdVal;
        self.nextClaimIdVal = self.nextClaimIdVal + (1);
        return ncId;
    }

    /**
     * @dev get the next gem id
     */
    function nextGemId(ComplexPoolData storage self) public returns (uint256) {
        uint256 ncId = self.nextGemIdVal;
        self.nextGemIdVal = self.nextGemIdVal + (1);
        return ncId;
    }

    /**
     * @dev increase the pool's difficulty by calculating the step increase portion and adding it to the eth price of the market
     */
    function increaseDifficulty(ComplexPoolData storage self) public {
        if (
            self.priceIncrementType ==
            INFTComplexGemPoolData.PriceIncrementType.COMPOUND
        ) {
            uint256 diffIncrease = self.ethPrice / (self.diffstep);
            self.ethPrice = self.ethPrice + (diffIncrease);
        } else if (
            self.priceIncrementType ==
            INFTComplexGemPoolData.PriceIncrementType.INVERSELOG
        ) {
            uint256 diffIncrease = self.diffstep / (self.ethPrice);
            self.ethPrice = self.ethPrice + (diffIncrease);
        }
    }

    /**
     * @dev the hash of the next gem to be minted
     */
    function nextGemHash(ComplexPoolData storage self)
        public
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        "gem",
                        address(self.pool),
                        self.nextGemIdVal
                    )
                )
            );
    }

    /**
     * @dev the hash of the next claim to be minted
     */
    function nextClaimHash(ComplexPoolData storage self)
        public
        view
        returns (uint256)
    {
        return
            (self.maxClaims != 0 && self.nextClaimIdVal <= self.maxClaims) ||
                self.maxClaims == 0
                ? uint256(
                    keccak256(
                        abi.encodePacked(
                            "claim",
                            address(self.pool),
                            self.nextClaimIdVal
                        )
                    )
                )
                : 0;
    }

    /**
     * @dev get the token hash at index
     */
    function allTokenHashes(ComplexPoolData storage self, uint256 ndx)
        public
        view
        returns (uint256)
    {
        return self.tokenHashes[ndx];
    }

    /**
     * @dev return the claim amount paid for this claim
     */
    function claimAmount(ComplexPoolData storage self, uint256 claimHash)
        public
        view
        returns (uint256)
    {
        return self.claimAmountPaid[claimHash];
    }

    /**
     * @dev the claim quantity (count of gems staked) for the given claim hash
     */
    function claimQuantity(ComplexPoolData storage self, uint256 claimHash)
        public
        view
        returns (uint256)
    {
        return self.claimQuant[claimHash];
    }

    /**
     * @dev the lock time for this claim hash. once past lock time a gem is minted
     */
    function claimUnlockTime(ComplexPoolData storage self, uint256 claimHash)
        public
        view
        returns (uint256)
    {
        return self.claimLockTimestamps[claimHash];
    }

    /**
     * @dev return the claim token amount for this claim hash
     */
    function claimTokenAmount(ComplexPoolData storage self, uint256 claimHash)
        public
        view
        returns (uint256)
    {
        return self.claimTokenAmountPaid[claimHash];
    }

    /**
     * @dev return the claim hash of the given gemhash
     */
    function gemClaimHash(ComplexPoolData storage self, uint256 gemHash)
        public
        view
        returns (uint256)
    {
        return self.gemClaims[gemHash];
    }

    /**
     * @dev return the token that was staked to create the given token hash. 0 if the native token
     */
    function stakedToken(ComplexPoolData storage self, uint256 claimHash)
        public
        view
        returns (address)
    {
        return self.claimLockToken[claimHash];
    }

    /**
     * @dev add a token that is allowed to be used to create a claim
     */
    function addAllowedToken(ComplexPoolData storage self, address token)
        public
    {
        if (!self.allowedTokens.exists(token) && token != WFTM) {
            self.allowedTokens.insert(token);
        }
    }

    /**
     * @dev  remove a token that is allowed to be used to create a claim
     */
    function removeAllowedToken(ComplexPoolData storage self, address token)
        public
    {
        if (self.allowedTokens.exists(token)) {
            self.allowedTokens.remove(token);
        }
    }

    /**
     * @dev deposit into pool
     */
    function deposit(
        ComplexPoolData storage self,
        address erc20token,
        uint256 tokenAmount
    ) public {
        if (erc20token == address(0)) {
            require(msg.sender.balance >= tokenAmount, "INSUFFICIENT_BALANCE");
            self.totalStakedEth = self.totalStakedEth + (msg.sender.balance);
        } else {
            require(
                IERC20(erc20token).balanceOf(msg.sender) >= tokenAmount,
                "INSUFFICIENT_BALANCE"
            );
            IERC20(erc20token).transferFrom(
                msg.sender,
                address(self.pool),
                tokenAmount
            );
        }
    }

    /**
     * @dev deposit NFT into pool
     */
    function depositNFT(
        ComplexPoolData storage self,
        address erc1155token,
        uint256 tokenId,
        uint256 tokenAmount
    ) public {
        require(
            IERC1155(erc1155token).balanceOf(msg.sender, tokenId) >=
                tokenAmount,
            "INSUFFICIENT_BALANCE"
        );
        IERC1155(erc1155token).safeTransferFrom(
            msg.sender,
            address(self.pool),
            tokenId,
            tokenAmount,
            ""
        );
    }

    /**
     * @dev withdraw pool contents
     */
    function withdraw(
        ComplexPoolData storage self,
        address erc20token,
        address destination,
        uint256 tokenAmount
    ) public {
        require(destination != address(0), "ZERO_ADDRESS");
        require(
            self.controllers[msg.sender] == true || msg.sender == self.governor,
            "UNAUTHORIZED"
        );
        if (erc20token == address(0)) {
            payable(destination).transfer(tokenAmount);
        } else {
            IERC20(erc20token).transferFrom(
                address(self.pool),
                address(destination),
                tokenAmount
            );
        }
    }

    /**
     * @dev withdraw pool NFT
     */
    function withdrawNFT(
        ComplexPoolData storage self,
        address erc1155token,
        address destination,
        uint256 tokenId,
        uint256 tokenAmount
    ) public {
        require(
            self.controllers[msg.sender] == true || msg.sender == self.governor,
            "UNAUTHORIZED"
        );
        require(erc1155token != address(0), "ZERO_ADDRESS");
        require(destination != address(0), "ZERO_ADDRESS");
        require(
            IERC1155(erc1155token).balanceOf(address(self.pool), tokenId) >=
                tokenAmount,
            "INSUFFICIENT_BALANCE"
        );
        IERC1155(erc1155token).safeTransferFrom(
            address(self.pool),
            address(destination),
            tokenId,
            tokenAmount,
            ""
        );
    }

    /**
     * @dev mint the genesis gems earned by the pools creator and funder
     */
    function mintGenesisGems(
        ComplexPoolData storage self,
        address creator,
        address funder
    ) public {
        require(self.multitoken != address(0), "NO_MULTITOKEN");
        require(
            creator != address(0) && funder != address(0),
            "ZERO_DESTINATION"
        );
        require(self.nextGemIdVal == 0, "ALREADY_MINTED");

        uint256 gemHash = nextGemHash(self);
        INFTGemMultiToken(self.multitoken).mint(creator, gemHash, 1);
        addToken(self, gemHash, INFTGemMultiToken.TokenType.GEM);
        // emit an event about a gem getting created
        emit NFTGemCreated(creator, address(self.pool), 0, gemHash, 1);

        gemHash = nextGemHash(self);
        INFTGemMultiToken(self.multitoken).mint(funder, gemHash, 1);
        addToken(self, gemHash, INFTGemMultiToken.TokenType.GEM);
        // emit an event about a gem getting created
        emit NFTGemCreated(funder, address(self.pool), 0, gemHash, 1);
    }
}
