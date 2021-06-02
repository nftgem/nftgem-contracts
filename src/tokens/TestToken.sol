// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

import "./ERC20.sol";

    /**
     * @dev a test token for whatever. mints 1m tokens to caller
     */
contract TestToken is ERC20 {
    constructor(string memory symbol, string memory name) ERC20(symbol, name) {
        _mint(msg.sender, 1000000 ether);
    }
}
