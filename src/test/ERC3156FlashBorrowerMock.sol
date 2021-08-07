// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract ERC3156FlashBorrowerMock is IERC3156FlashBorrower {
    bytes32 constant internal RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    bool immutable _enableApprove;
    bool immutable _enableReturn;

    event BalanceOf(address token, address account, uint256 value);
    event TotalSupply(address token, uint256 value);

    constructor(bool enableReturn, bool enableApprove) {
        _enableApprove = enableApprove;
        _enableReturn = enableReturn;
    }

    function onFlashLoan(
        address /*initiator*/,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) public override returns (bytes32) {
        // require(msg.sender == token, "");

        emit BalanceOf(token, address(this), IERC20(token).balanceOf(address(this)));
        emit TotalSupply(token, IERC20(token).totalSupply());

        if (data.length > 0) {
            // test code invocation
        }
        if (_enableApprove) {
            IERC20(token).approve(msg.sender, amount + fee);
        }

        return _enableReturn ? RETURN_VALUE : bytes32(0);
    }
}