// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../access/Controllable.sol";
import "../interfaces/INFTGemFeeManager.sol";

contract NFTGemFeeManager is Controllable, INFTGemFeeManager {
    address private operator;

    uint256 public constant MINIMUM_LIQUIDITY_HASH =
        uint256(keccak256("min_liquidity"));
    uint256 public constant POOL_FEE_HASH =
        uint256(keccak256(abi.encodePacked("pool_fee")));
    uint256 public constant WRAP_GEM_HASH =
        uint256(keccak256(abi.encodePacked("wrap_gem")));
    uint256 public constant FLASH_LOAN_HASH =
        uint256(keccak256(abi.encodePacked("flash_loan")));

    uint256 private constant MINIMUM_LIQUIDITY = 50;
    uint256 private constant POOL_FEE = 2000;
    uint256 private constant WRAP_GEM = 2000;
    uint256 private constant FLASH_LOAN = 10000;

    mapping(uint256 => uint256) private fees;

    /**
     * @dev constructor
     */
    constructor() {
        _addController(msg.sender);
        fees[MINIMUM_LIQUIDITY_HASH] = MINIMUM_LIQUIDITY;
        fees[POOL_FEE_HASH] = POOL_FEE;
        fees[WRAP_GEM_HASH] = WRAP_GEM;
        fees[FLASH_LOAN_HASH] = FLASH_LOAN;
    }

    /**
     * @dev receive funds
     */
    receive() external payable {
        //
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function fee(uint256 feeHash)
        external
        view
        override
        returns (uint256 feeRet)
    {
        feeRet = fees[feeHash];
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFee(uint256 feeHash, uint256 _fee)
        external
        override
        onlyController
    {
        fees[feeHash] = _fee;
        emit FeeChanged(operator, feeHash, _fee);
    }

    /**
     * @dev get the balance of this fee manager. Pass a zero address in for FTM balance
     */
    function balanceOf(address token) external view override returns (uint256) {
        return
            token == address(0)
                ? address(this).balance
                : IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev transfer ETH from this contract to the to given recipient
     */
    function transferEth(address payable recipient, uint256 amount)
        external
        override
        onlyController
    {
        recipient.transfer(amount);
    }

    /**
     * @dev transfer tokens from this contract to the to given recipient
     */
    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external override onlyController {
        IERC20(token).transfer(recipient, amount);
    }
}
