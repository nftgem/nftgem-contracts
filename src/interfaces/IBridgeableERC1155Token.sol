// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow the bridge to mint and burn tokens
/// bridge must be able to mint and burn tokens on the multitoken contract
interface IBridgeableERC1155Token {
    // mint some tokens to the specfiied address
    function mint(
        address recipient,
        uint256 tokenHash,
        uint256 amount
    ) external;

    // burn tokens of specified amount from the specified address
    function burn(
        address recipient,
        uint256 tokenHash,
        uint256 amount
    ) external;
}
