// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWrappedFtm {
    // deposit wraps received FTM tokens as wFTM in 1:1 ratio by minting
    // the received amount of FTMs in wFTM on the sender's address.
    function deposit() external payable returns (uint256);

    // withdraw unwraps FTM tokens by burning specified amount
    // of wFTM from the caller address and sending the same amount
    // of FTMs back in exchange.
    function withdraw(uint256 amount) external returns (uint256);
}
