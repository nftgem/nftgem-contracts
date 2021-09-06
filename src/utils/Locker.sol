// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "../interfaces/ILocker.sol";

contract Locker is ILocker, ERC1155Holder {
    // locker contents
    mapping(uint256 => LockerContents) private _lockerContents;

    /// @notice call to drop off your token
    /// @param unlockTokenAddress address of unlock token
    /// @param unlockTokenHash unlock token hash
    /// @param awardTokenAddress token address
    /// @param awardTokenHash token hash
    /// @param awardQty token hash
    function dropOff(
        address unlockTokenAddress,
        uint256 unlockTokenHash,
        address awardTokenAddress,
        uint256 awardTokenHash,
        uint256 awardQty
    ) external override {
        // there should be nothing where we are dropping off
        require(
            _lockerContents[unlockTokenHash].unlockTokenAddress == address(0),
            "Token already registered"
        );

        // make sure we are depositing > 0 contents
        require(awardQty > 0, "Award quantity must be greater than 0");

        // make sure we have enough balance of award token to deposit
        require(
            IERC1155(awardTokenAddress).balanceOf(msg.sender, awardTokenHash) >=
                awardQty,
            "Sender Balance must be greater or equal than the award quantity"
        );
        // store the locker contents
        _lockerContents[unlockTokenHash] = LockerContents(
            unlockTokenAddress,
            unlockTokenHash,
            awardTokenAddress,
            awardTokenHash,
            awardQty
        );
        // deposit the award token into the locker
        IERC1155(awardTokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            awardTokenHash,
            awardQty,
            ""
        );
        // emit an event
        emit LockerContentsDroppedOff(
            msg.sender,
            awardTokenAddress,
            awardTokenHash,
            awardQty
        );
    }

    /// @param tokenHashKey token hash
    function contents(uint256 tokenHashKey)
        external
        view
        override
        returns (LockerContents memory _locker)
    {
        _locker = _lockerContents[tokenHashKey];
    }

    /// @notice pick up the token
    /// @param _openCode the pickup code
    /// @param receiver the receiver of the contents
    function _pickupToken(uint256 _openCode, address receiver) internal {
        // make sure we still have tokens to give
        require(_lockerContents[_openCode].awardQty > 0, "No token to pick up");

        uint256 qty = _lockerContents[_openCode].awardQty;
        // set to zero first to prevent reentrancy
        _lockerContents[_openCode].awardQty = 0;

        // then send the token
        IERC1155(_lockerContents[_openCode].awardTokenAddress).safeTransferFrom(
                address(this),
                receiver,
                _lockerContents[_openCode].awardTokenHash,
                qty,
                ""
            );

        // and emit an event
        emit LockerContentsPickedUp(
            receiver,
            _lockerContents[_openCode].awardTokenAddress,
            _lockerContents[_openCode].awardTokenHash,
            qty
        );
    }

    /// @notice call to pick up your erc 11555 NFT given a source erc1155 in your possession
    /// @param unlockTokenHashKey the token hash which will unlock your locker
    function pickUpTokenWithKey(uint256 unlockTokenHashKey) external override {
        // get the locker contents
        LockerContents memory contents = _lockerContents[unlockTokenHashKey];

        // require unlock token hash matches
        require(
            contents.unlockTokenHash == unlockTokenHashKey,
            "Unlock token missmatched"
        );

        // require there be a quantity to pick up
        require(contents.awardQty > 0, "No token to pick up");

        // require user to have unlock nft in posession
        require(
            IERC1155(contents.unlockTokenAddress).balanceOf(
                msg.sender,
                unlockTokenHashKey
            ) > 0,
            "No unlock nft available"
        );

        // pick up the token and generate event
        _pickupToken(unlockTokenHashKey, msg.sender);
    }
}
