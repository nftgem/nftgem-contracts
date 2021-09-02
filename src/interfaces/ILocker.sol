// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

/// @dev Interface for the NFT Royalty Standard
///
interface ILocker {
    // the contents of the locker
    struct LockerContents {
        // unlock
        address unlockTokenAddress;
        uint256 unlockTokenHash;
        // award
        address awardTokenAddress;
        uint256 awardTokenHash;
        uint256 awardQty;
    }

    /// @notice call to drop off your gem
    /// @param unlockTokenAddress address of token
    /// @param unlockTokenHash address of token
    /// @param awardTokenAddress token hash
    /// @param awardTokenHash token hash
    /// @param awardQty token hash
    function dropOff(
        address unlockTokenAddress,
        uint256 unlockTokenHash,
        address awardTokenAddress,
        uint256 awardTokenHash,
        uint256 awardQty
    ) external;

    /// @notice examine contents at tokenhash
    /// @param tokenHashKey token hash
    function contents(uint256 tokenHashKey)
        external
        view
        returns (LockerContents memory);

    /// @notice call to pick up  your erc 11555 NFT using a key (your token hash)
    /// @param tokenHashKey token hash
    function pickUpTokenWithKey(uint256 tokenHashKey) external;

    // fired when a gem is dropped off
    event LockerContentsDroppedOff(
        address depositor,
        address token,
        uint256 tokenHash,
        uint256 qty
    );

    // fired when a gem is picked up
    event LockerContentsPickedUp(
        address receiver,
        address token,
        uint256 tokenHash,
        uint256 qty
    );
}
