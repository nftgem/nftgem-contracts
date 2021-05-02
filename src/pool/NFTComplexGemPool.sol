// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../utils/Initializable.sol";
import "../access/Controllable.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemFeeManager.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/INFTComplexGemPool.sol";
import "../interfaces/INFTGemGovernor.sol";
import "../interfaces/ISwapQueryHelper.sol";
import "../tokens/ERC1155Holder.sol";

import "../libs/SafeMath.sol";
import "./NFTComplexGemPoolData.sol";

contract NFTComplexGemPool is NFTComplexGemPoolData, INFTComplexGemPool, ERC1155Holder, Controllable {
    using SafeMath for uint256;

    // governor and multitoken target
    address private _multitoken;
    address private _governor;
    address private _feeTracker;
    bool private _visible;
    uint256 private _category;

    address private erc20Creator;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev initializer called when contract is deployed
     */
    function initialize(
        string memory __symbol,
        string memory __name,
        uint256 __ethPrice,
        uint256 __minTime,
        uint256 __maxTime,
        uint256 __diffstep,
        uint256 __maxClaims,
        address __allowedToken
    ) external override initializer {
        _symbol = __symbol;
        _name = __name;
        _ethPrice = __ethPrice;
        _minTime = __minTime;
        _maxTime = __maxTime;
        _diffstep = __diffstep;
        _maxClaims = __maxClaims;
        _visible = true;
        if (__allowedToken != address(0)) {
            _allowedTokens.push(__allowedToken);
            _isAllowedMap[__allowedToken] = true;
        }
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setGovernor(address addr) external override {
        require(_controllers[msg.sender] = true || msg.sender == _governor, "UNAUTHORIZED");
        _governor = addr;
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setFeeTracker(address addr) external override {
        require(_controllers[msg.sender] = true || msg.sender == _governor, "UNAUTHORIZED");
        _feeTracker = addr;
    }

    /**
     * @dev set the multitoken that this pool will mint new tokens on. Must be a controller of the multitoken
     */
    function setMultiToken(address token) external override {
        require(_controllers[msg.sender] = true || msg.sender == _governor, "UNAUTHORIZED");
        _multitoken = token;
    }

    function setSwapHelper(address) external override {}

    /**
     * @dev set market visibility
     */
    function setVisible(bool visible) external override {
        require(_controllers[msg.sender] = true || msg.sender == _governor, "UNAUTHORIZED");
        _visible = visible;
    }

    /**
     * @dev set market visibility
     */
    function visible() external view override returns (bool v) {
        v = _visible;
    }

    /**
     * @dev set category category
     */
    function setCategory(uint256 category) external override {
        require(_controllers[msg.sender] = true || msg.sender == _governor, "UNAUTHORIZED");
        _category = category;
    }

    /**
     * @dev set market category
     */
    function category() external view override returns (uint256 c) {
        c = _category;
    }

    /**
     * @dev mint the genesis gems earned by the pools creator and funder
     */
    function mintGenesisGems(address creator, address funder) external override {
        require(_multitoken != address(0), "NO_MULTITOKEN");
        require(creator != address(0) && funder != address(0), "ZERO_DESTINATION");
        require(_nextGemId == 0, "ALREADY_MINTED");

        uint256 gemHash = _nextGemHash();
        INFTGemMultiToken(_multitoken).mint(creator, gemHash, 1);
        _addToken(gemHash, 2);

        gemHash = _nextGemHash();
        INFTGemMultiToken(_multitoken).mint(creator, gemHash, 1);
        _addToken(gemHash, 2);
    }

    /**
     * @dev the external version of the above
     */
    function createClaim(uint256 timeframe) external payable override {}

    /**
     * @dev the external version of the above
     */
    function createClaims(uint256 timeframe, uint256 count) external payable override {
        _createClaims(timeframe, count);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claim(address erc20token, uint256 tokenAmount) external override {}

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claims(
        address erc20token,
        uint256 tokenAmount,
        uint256 count
    ) external override {
        _createERC20Claims(erc20token, tokenAmount, count);
    }

    /**
     * @dev rescue funds
     */
    function rescue(address erc20token, uint256 tokenAmount) external override {
        require(_controllers[msg.sender] = true || msg.sender == _governor, "UNAUTHORIZED");
        if (erc20token == address(0)) {
            payable(_feeTracker).transfer(tokenAmount);
        } else {
            IERC20(erc20token).transferFrom(address(this), address(_feeTracker), tokenAmount);
        }
    }

    /**
     * @dev attempt to create a claim using the given timeframe
     */
    function _createClaims(uint256 timeframe, uint256 count) internal {
        // minimum timeframe
        require(timeframe >= _minTime, "TIMEFRAME_TOO_SHORT");
        // no ETH
        require(msg.value != 0, "ZERO_BALANCE");
        // zero qty
        require(count != 0, "ZERO_QUANTITY");
        // maximum timeframe
        require((_maxTime != 0 && timeframe <= _maxTime) || _maxTime == 0, "TIMEFRAME_TOO_LONG");

        uint256 adjustedBalance = msg.value.div(count);
        // cost given this timeframe

        uint256 cost = _ethPrice.mul(_minTime).div(timeframe);
        require(adjustedBalance >= cost, "INSUFFICIENT_ETH");

        // get the nest claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(timeframe);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = cost.mul(count);
        claimQuant[claimHash] = count;

        transferInputReqsFrom(claimHash, msg.sender, address(this), count);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, cost);

        emit NFTGemClaimCreated(msg.sender, address(this), claimHash, timeframe, count, cost);

        // increase the staked eth balance
        _totalStakedEth = _totalStakedEth.add(cost.mul(count));

        // return the extra to sender
        if (msg.value > cost.mul(count)) {
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(cost.mul(count))}("");
            require(success, "REFUND_FAILED");
        }
    }

    /**
     * @dev crate multiple gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function _createERC20Claims(
        address erc20token,
        uint256 tokenAmount,
        uint256 count
    ) internal {}

    /**
     * @dev collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
     */
    function collectClaim(uint256 claimHash) external override {
        // validation checks - disallow if not owner (holds coin with claimHash)
        // or if the unlockTime amd unlockPaid data is in an invalid state
        require(IERC1155(_multitoken).balanceOf(msg.sender, claimHash) == 1, "NOT_CLAIM_OWNER");
        uint256 unlockTime = claimLockTimestamps[claimHash];
        uint256 unlockPaid = claimAmountPaid[claimHash];
        require(unlockTime != 0 && unlockPaid > 0, "INVALID_CLAIM");

        // grab the erc20 token info if there is any
        address tokenUsed = claimLockToken[claimHash];
        uint256 unlockTokenPaid = claimTokenAmountPaid[claimHash];

        // check the maturity of the claim - only issue gem if mature
        bool isMature = unlockTime < block.timestamp;

        //  burn claim and transfer money back to user
        INFTGemMultiToken(_multitoken).burn(msg.sender, claimHash, 1);

        // calculate fee portion using fee tracker
        uint256 feePortion = 0;
        if (isMature == true) {
            uint256 divisor = INFTGemFeeManager(_feeTracker).feeDivisor(address(0));
            feePortion = unlockPaid.div(divisor);
        }
        // transfer the ETH fee to fee tracker
        payable(_feeTracker).transfer(feePortion);
        // transfer the ETH back to user
        payable(msg.sender).transfer(unlockPaid.sub(feePortion));

        // emit an event that the claim was redeemed for ETH
        emit NFTGemClaimRedeemed(msg.sender, address(this), claimHash, unlockPaid, feePortion);

        // deduct the total staked ETH balance of the pool
        _totalStakedEth = _totalStakedEth.sub(unlockPaid);

        // return any erc1155 tokens they staked
        if (claimIds[claimHash].length > 0) {
            IERC1155(_multitoken).safeBatchTransferFrom(
                address(this),
                msg.sender,
                claimIds[claimHash],
                claimQuantities[claimHash],
                ""
            );
            delete claimIds[claimHash];
            delete claimQuantities[claimHash];
        }

        // if all this is happening before the unlocktime then we exit
        // without minting a gem because the user is withdrawing early
        if (!isMature) {
            return;
        }

        // get the next gem hash, increase the staking sifficulty
        // for the pool, and mint a gem token back to account
        uint256 nextHash = this.nextGemHash();

        // mint the gem
        INFTGemMultiToken(_multitoken).mint(msg.sender, nextHash, claimQuant[claimHash]);
        _addToken(nextHash, 2);

        // maybe mint a governance token
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, unlockPaid);

        // emit an event about a gem getting created
        emit NFTGemCreated(msg.sender, address(this), claimHash, nextHash, claimQuant[claimHash]);
    }

    function setValidateErc20(bool) external override {}

    function validateErc20() external view override returns (bool) {
        return true;
    }
}
