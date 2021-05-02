// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/ISwapQueryHelper.sol";
import "../libs/SafeMath.sol";

contract ComplexERC20ClaimCreator {
    using SafeMath for uint256;

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev crate multiple gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function validate(
        address swapHelper,
        address erc20token,
        uint256 tokenAmount,
        uint256 count
    ) public {
        // check authorized sender
        require(owner == msg.sender, "UNAUTHORIZED");

        // must be a valid address
        require(erc20token != address(0), "INVALID_ERC20_TOKEN");

        // token is allowed
        require(
            (INFTComplexGemPoolData(owner).allowedTokensLength() > 0 &&
                INFTComplexGemPoolData(owner).isTokenAllowed(erc20token)) ||
                INFTComplexGemPoolData(owner).allowedTokensLength() == 0,
            "TOKEN_DISALLOWED"
        );

        // zero qty
        require(count != 0, "ZERO_QUANTITY");

        // Uniswap pool must exist
        require(ISwapQueryHelper(swapHelper).hasPool(erc20token) == true, "NO_UNISWAP_POOL");

        // must have an amount specified
        require(tokenAmount >= 0, "NO_PAYMENT_INCLUDED");

        // get a quote in ETH for the given token.
        (uint256 ethereum, uint256 tokenReserve, uint256 ethReserve) =
            ISwapQueryHelper(swapHelper).coinQuote(erc20token, tokenAmount.div(count));

        // make sure the convertible amount is has reserves > 100x the token
        require(ethReserve >= ethereum.mul(100).mul(count), "INSUFFICIENT_ETH_LIQUIDITY");

        // make sure the convertible amount is has reserves > 100x the token
        require(tokenReserve >= tokenAmount.mul(100).mul(count), "INSUFFICIENT_TOKEN_LIQUIDITY");

        // make sure the convertible amount is less than max price
        require(ethereum <= INFTComplexGemPoolData(owner).ethPrice(), "OVERPAYMENT");

        // calculate the maturity time given the converted eth
        uint256 maturityTime =
            INFTComplexGemPoolData(owner).ethPrice().mul(INFTComplexGemPoolData(owner).minTime()).div(ethereum);

        // make sure the convertible amount is less than max price
        require(maturityTime >= INFTComplexGemPoolData(owner).minTime(), "INSUFFICIENT_TIME");

        // get the next claim hash, revert if no more claims
        uint256 claimHash = INFTComplexGemPoolData(owner).nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");
    }
}
