// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./INFTGemMultiToken.sol";

/// @dev Interface for the NFT Royalty Standard
///
interface ILocker {
    struct LockerContents {
        address tokenAddress;
        uint256 tokenHash;
        uint256 quantity;
    }

    function initialize(address multitoken) external;

    /// @notice call to drop off your gem
    /// @param unlockTokenHash address of token
    /// @param awardToken token hash
    /// @param awardTokenHash token hash
    /// @param awardQty token hash
    /// @return _openCode - address of who should be sent the royalty payment
    function dropOff(
        uint256 unlockTokenHash,
        address awardToken,
        uint256 awardTokenHash,
        uint256 awardQty
    ) external returns (uint256 _openCode);

    /// @notice call to pick up  your erc 11555 NFT
    /// @return _result - address of who should be sent the royalty payment
    function pickUpGem() external returns (bool _result);

    /// @notice call to pick up  your erc 11555 NFT using a key
    /// @param tokenHashKey token hash
    function pickUpGemWithKey(uint256 tokenHashKey)
        external
        returns (bool _pickedUp);

    event LockerContentsDroppedOff(
        address depositor,
        address token,
        uint256 tokenHash,
        uint256 qty
    );
    event LockerContentsPickedUp(
        address receiver,
        address token,
        uint256 tokenHash,
        uint256 qty
    );
}

contract Locker is ILocker, ERC1155Holder, Initializable {
    address private _multitoken;
    mapping(uint256 => LockerContents) private _lockerContents;

    function initialize(address multitoken) external override initializer {
        _multitoken = multitoken;
    }

    /// @notice call to drop off your gem
    /// @param unlockTokenHash address of token
    /// @param awardToken token hash
    /// @param awardTokenHash token hash
    /// @param awardQty token hash
    /// @return _openCode - address of who should be sent the royalty payment
    function dropOff(
        uint256 unlockTokenHash,
        address awardToken,
        uint256 awardTokenHash,
        uint256 awardQty
    ) external override returns (uint256 _openCode) {
        // the open code (really a receipt) is a hash of the unlock token and token hash
        _openCode = uint256(
            keccak256(abi.encodePacked(_multitoken, unlockTokenHash))
        );

        // there should be nothing where we are dropping off
        require(
            _lockerContents[_openCode].quantity == 0,
            "Token already registered"
        );

        // make sure we are depositing > 0 contents
        require(awardQty > 0, "Award quantity must be greater than 0");

        // then transfer the token to us
        IERC1155(_lockerContents[_openCode].tokenAddress).safeTransferFrom(
            msg.sender,
            address(this),
            _lockerContents[_openCode].tokenHash,
            awardQty,
            ""
        );

        // build the locker contents
        LockerContents memory lockerContents = LockerContents(
            awardToken,
            awardTokenHash,
            awardQty
        );

        // store the locker contents
        _lockerContents[_openCode] = lockerContents;
        // emit an event
        emit LockerContentsDroppedOff(
            msg.sender,
            awardToken,
            awardTokenHash,
            awardQty
        );
    }

    /// @notice pick up the gem
    /// @param _openCode the pickup code
    /// @return success - is successful
    function _pickUpGem(uint256 _openCode) internal returns (bool success) {
        success = false;

        // make sure we still have gems to give
        uint256 sendQty = _lockerContents[_openCode].quantity;
        require(_lockerContents[_openCode].quantity > 0, "No gem to pick up");

        // set to zero first to prevent reentrancy
        _lockerContents[_openCode].quantity = 0;

        // then send the token
        IERC1155(_lockerContents[_openCode].tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _lockerContents[_openCode].tokenHash,
            sendQty,
            ""
        );

        // and emit an event
        emit LockerContentsPickedUp(
            msg.sender,
            _multitoken,
            _lockerContents[_openCode].tokenHash,
            sendQty
        );

        success = true;
    }

    /// @notice call to pick up your erc 11555 NFT. searches through all your gems
    /// and might fail if you have many gems. In that case, call pickupGemWithCode
    /// @return _result - is successful
    function pickUpGem() external override returns (bool _result) {
        // get users held bitgems
        uint256[] memory heldTokens = INFTGemMultiToken(_multitoken).heldTokens(
            msg.sender
        );
        // iterate through em looking for one that contains something in a locker
        for (uint256 i = 0; i < heldTokens.length; i++) {
            uint256 tokenKey = heldTokens[i];
            // skip zero balances (shouldnt happen but just in case)
            if (IERC1155(_multitoken).balanceOf(msg.sender, tokenKey) == 0) {
                continue;
            }
            // create the open code for the locker (we need to create the
            // code, there are no lists of these codes, only the mappings)
            uint256 _openCode = uint256(
                keccak256(abi.encodePacked(_multitoken, tokenKey))
            );
            // if the locker contents keyed by that code also match the
            // address and token hash, and there's a quanntity, then we have
            // found the gem we're looking for
            if (
                _lockerContents[_openCode].tokenAddress == _multitoken &&
                _lockerContents[_openCode].tokenHash == tokenKey &&
                _lockerContents[_openCode].quantity > 0
            ) {
                // pick up the gem and generate event
                _result = _pickUpGem(_openCode);
                break;
            }
        }
    }

    /// @notice call to pick up your erc 11555 NFT given a source token hash in youre possession.
    /// Use this method if you have more  gems in your possession than you can process with one call
    /// @return _pickedUp - got picked up
    function pickUpGemWithKey(uint256 tokenHashKey)
        external
        override
        returns (bool _pickedUp)
    {
        // code, there are no lists of these codes, only the mappings)
        uint256 _openCode = uint256(
            keccak256(abi.encodePacked(_multitoken, tokenHashKey))
        );
        // if the locker contents keyed by that code also match the
        // address and token hash, and there's a quanntity, then we have
        // found the gem we're looking for
        if (
            _lockerContents[_openCode].tokenAddress == _multitoken &&
            _lockerContents[_openCode].tokenHash == tokenHashKey &&
            _lockerContents[_openCode].quantity > 0
        ) {
            // pick up the gem and generate event
            _pickedUp = _pickUpGem(_openCode);
        }
    }
}
