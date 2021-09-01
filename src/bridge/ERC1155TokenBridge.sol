// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/IERC1155TokenBridge.sol";
import "../interfaces/IBridgeableERC1155Token.sol";

contract ERC1155TokenBridge is IERC1155TokenBridge {

    /// @dev register a new token that can be moved by the bridge
    function registerToken(address _bridgeable)
        external
        override
        returns (bool)
    {
        try IERC1155(_bridgeable).balanceOf(msg.sender) 
        catch (e) {  
            return false;
        }
        return 
    }

    /// @dev unregister a token from the bridge
    function unregisterToken(address _bridgeable)
        external
        override
        returns (bool)
    {}

    /// @dev register a new validator that can validate transfers
    function registerValidator(address validatorAddress)
        external
        override
        returns (bool)
    {}

    /// @dev unregister a validator from the bridge
    function unregisterValidator(address validatorAddress)
        external
        override
        returns (bool)
    {}

    /// @dev the list of validators that can validate transfers
    function validators() external override returns (bool) {}

    /// @dev called by each validator to validate a transfer
    function validateTransfer(
        uint256 _receiptId,
        uint32 _networkId,
        address _from,
        address _to,
        uint256[] memory _tokenId,
        uint256[] memory _amount
    ) external override returns (bool) {}

    /// @dev called by the bridge to confirm a transfer. This burns the source token(s)
    function confirmTransfer(uint256 _receiptId)
        external
        override
        returns (bool)
    {}

    /// @dev cancel a transfer that has not been confirmed. This reverts the transfer
    /// @dev and returns the source token(s) to the sender
    function cancelTransfer(uint256 _receiptId)
        external
        override
        returns (bool)
    {}

    /// @dev get the data related to this transfer
    function getTransferData(uint256 _receiptId)
        external
        override
        returns (TransferStatus)
    {}

    /// @dev get the status of this transfer
    function getTransferStatus(uint256 _receiptId)
        external
        override
        returns (TransferStatus)
    {}

    /// @dev perform an erc1155 transfer from the calling network to the target network
    /// @dev specified by the networkId and the target address.
    function networkTransferFrom(
        uint32 networkId,
        address tokenAddress,
        address from,
        address to,
        uint256[] memory tokenHash,
        uint256[] memory amount
    ) external override returns (uint256 receipt, uint256 feeAmount) {
        receipt = 0;
        feeAmount = 0;
    }
}