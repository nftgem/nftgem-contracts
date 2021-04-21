// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../interfaces/IProposalData.sol";

contract CreateCustomGemPoolProposalData is ICreateCustomGemPoolProposalData {

    string private symbol;
    string private name;
    bytes private bytecode;

    constructor(
        bytes memory _bytecode,
        string memory _symbol,
        string memory _name
    ) {
        bytecode = _bytecode;
        symbol = _symbol;
        name = _name;
    }

    function data()
        external
        view
        override
        returns (
            bytes memory,
            string memory,
            string memory
        )
    {
        return (bytecode, symbol, name);
    }
}
