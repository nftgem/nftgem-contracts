// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// defines the interface for the bridge contract. This contract implements a decentralized
/// bridge for an erc1155 token which enables users to transfer erc1155 tokens between supported networks.
/// users request a transfer in one network, which registers the transfer in the bridge contract, and generates
/// an event. This event is seen by a validator, who validates the transfer by calling the validate method on
/// the target network. Once a majority of validators have validated the transfer, the transfer is executed on the
/// target network by minting the approriate token type and burning the appropriate amount of the source token,
/// which is held in custody by the bridge contract until the transaction is confirmed. In order to participate,
/// validators must register with the bridge contract and put up a deposit as collateral.  The deposit is returned
/// to the validator when the validator self-removes from the validator set. If the validator acts in a way that
/// violates the rules of the bridge contract - namely the validator fails to validate a number of transfers,
/// or the validator posts some number of transfers which remain unconfirmed, then the validator is removed from the
/// validator set and their bond is distributed to other validators. The validator will then need to re-bond and
/// re-register. Repeated violations of the rules of the bridge contract will result in the validator being removed
/// from the validator set permanently via a ban.
interface IERC1155TokenBridge {
    struct Validator {
        address operatorAddress;
        address validatorAddress;
        uint256 bondedAmount;
    }

    enum TransferStatus {
        CREATED,
        PENDING,
        COMPLETED
    }

    struct NetworkTransferRequest {
        uint256 id;
        uint32 networkId;
        address from;
        address to;
        uint256[] tokenHash;
        uint256[] amount;
        TransferStatus status;
    }

    event NetworkTransfer(
        address tokenAddress,
        uint256 indexed receiptId,
        uint32 fromNetworkId,
        address indexed _from,
        uint32 toNetworkId,
        address indexed _to,
        uint256[] _id,
        uint256[] _value,
        bool isBatch
    );

    event NetworkTransferStatus(
        uint256 indexed receiptId,
        NetworkTransferStatus status
    );

    event TokenRegistered(
        address indexed controller,
        address indexed tokenAddress
    );

    event TokenUnregistered(
        address indexed controller,
        address indexed tokenAddress
    );

    event TransferValidated(
        uint256 indexed validator,
        uint256 indexed receiptValidated
    );

    event TransferConfirmed(uint256 indexed receiptConfirmed);

    event ValidatorRegistered(
        address indexed validator,
        uint256 bondAmount,
        uint256 newTotalValidators
    );

    event ValidatorUpdated(address indexed validator, Validator validatorData);

    event ValidatorUnregistered(
        address indexed validator,
        uint256 newTotalValidators
    );

    event ValidatorPenalized(address indexed validator, uint256 penalty);

    event ValidatorBanned(address indexed validator);

    function registerToken(address _bridgeable) external returns (bool);

    function unregisterToken(address _bridgeable) external returns (bool);

    function registerValidator(address validatorAddress)
        external
        returns (bool);

    function unregisterValidator(address validatorAddress)
        external
        returns (bool);

    function validators() external returns (bool);

    function validateTransfer(
        uint256 _receiptId,
        uint32 _networkId,
        address _from,
        address _to,
        uint256[] memory _tokenId,
        uint256[] memory _amount
    ) external returns (bool);

    function confirmTransfer(uint256 _receiptId) external returns (bool);

    function getTransferData(uint256 _receiptId)
        external
        returns (TransferStatus);

    function getTransferStatus(uint256 _receiptId)
        external
        returns (TransferStatus);

    function networkTransferFrom(
        uint32 networkId,
        address tokenAddress,
        address from,
        address to,
        uint256[] memory tokenHash,
        uint256[] memory amount
    ) external returns (uint256 receipt, uint256 feeAmount);
}
