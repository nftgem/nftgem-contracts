// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../interfaces/IProposalData.sol";

contract TransferPoolFundsProposalData is ITransferPoolFundsProposalData {
    address private token;
    address private pool;
    address private destination;
    uint256 private amount;

    constructor(
        address _token,
        address _pool,
        address _destination,
        uint256 _amount
    ) {
        token = _token;
        pool = _pool;
        destination = _destination;
        amount = _amount;
    }

    function data()
        external
        view
        override
        returns (
            address,
            address,
            address,
            uint256
        )
    {
        return (token, pool, destination, amount);
    }
}
