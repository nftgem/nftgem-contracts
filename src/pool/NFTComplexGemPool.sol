// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTGemFeeManager.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/INFTComplexGemPool.sol";
import "../interfaces/INFTGemGovernor.sol";
import "../interfaces/ISwapQueryHelper.sol";

import "../utils/Initializable.sol";
import "../tokens/ERC1155Holder.sol";

import "../libs/AddressSet.sol";
import "../libs/SafeMath.sol";

import "./NFTComplexGemPoolData.sol";

contract NFTComplexGemPool is NFTComplexGemPoolData, INFTComplexGemPool, ERC1155Holder {
    using SafeMath for uint256;
    using AddressSet for AddressSet.Set;
    using ComplexPoolLib for ComplexPoolLib.ComplexPoolData;

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address controller) external {
        require(
            poolData.controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        poolData.controllers[controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address caddress) external view returns (bool) {
        return poolData.controllers[caddress];
    }

    /**
     * @dev Check if this address is a controller
     */
    function relinquishControl() external {
        require(
            poolData.controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        poolData.controllers[msg.sender] = false;
    }

    constructor() {
        poolData.controllers[msg.sender] = true;
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
    ) external override onlyController {
        poolData.pool = address(this);
        poolData.symbol = __symbol;
        poolData.name = __name;
        poolData.ethPrice = __ethPrice;
        poolData.minTime = __minTime;
        poolData.maxTime = __maxTime;
        poolData.diffstep = __diffstep;
        poolData.maxClaims = __maxClaims;
        poolData.visible = true;
        if (__allowedToken != address(0)) {
            poolData.allowedTokens.insert(__allowedToken);
        }
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setGovernor(address addr) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
        poolData.governor = addr;
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setFeeTracker(address addr) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
        poolData.feeTracker = addr;
    }

    /**
     * @dev set the multitoken that this pool will mint new tokens on. Must be a controller of the multitoken
     */
    function setMultiToken(address addr) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
        poolData.multitoken = addr;
    }

    /**
     * @dev set the AMM swap helper that gets token prices
     */
    function setSwapHelper(address addr) external override {
        require(poolData.controllers[msg.sender] = true || msg.sender == poolData.governor, "UNAUTHORIZED");
        poolData.swapHelper = addr;
    }

    /**
     * @dev mint the genesis gems earned by the pools creator and funder
     */
    function mintGenesisGems(address creator, address funder) external override {
        poolData.mintGenesisGems(creator, funder);
    }

    /**
     * @dev the external version of the above
     */
    function createClaim(uint256 timeframe) external payable override {
        poolData.createClaims(timeframe, 1);
    }

    /**
     * @dev the external version of the above
     */
    function createClaims(uint256 timeframe, uint256 count) external payable override {
        poolData.createClaims(timeframe, count);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claim(address erc20token, uint256 tokenAmount) external override {
        poolData.createERC20Claims(erc20token, tokenAmount, 1);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claims(
        address erc20token,
        uint256 tokenAmount,
        uint256 count
    ) external override {
        poolData.createERC20Claims(erc20token, tokenAmount, count);
    }

    /**
     * @dev collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
     */
    function collectClaim(uint256 claimHash) external override {
        poolData.collectClaim(claimHash);
    }

    /**
     * @dev deposit into pool
     */
    function deposit(address erc20token, uint256 tokenAmount) external override {
        poolData.deposit(erc20token, tokenAmount);
    }

    /**
     * @dev deposit into pool
     */
    function depositNFT(
        address erc1155token,
        uint256 tokenId,
        uint256 tokenAmount
    ) external override {
        poolData.depositNFT(erc1155token, tokenId, tokenAmount);
    }

    /**
     * @dev withdraw pool contents
     */
    function withdraw(
        address erc20token,
        address destination,
        uint256 tokenAmount
    ) external override {
        poolData.withdraw(erc20token, destination, tokenAmount);
    }

    /**
     * @dev withdraw pool contents
     */
    function withdrawNFT(
        address erc1155token,
        address destination,
        uint256 tokenId,
        uint256 tokenAmount
    ) external override {
        poolData.withdrawNFT(erc1155token, destination, tokenId, tokenAmount);
    }
}
