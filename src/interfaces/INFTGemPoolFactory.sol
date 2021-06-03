// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface INFTGemPoolFactory {
    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event NFTGemPoolCreated(
        address gemPoolAddress,
        string gemSymbol,
        string gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    );

    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event CustomNFTGemPoolCreated(address gemPoolAdress, string gemSymbol, string gemName);

    function nftGemPools() external view returns (address[] memory);

    function getNFTGemPool(uint256 _symbolHash) external view returns (address);

    function allNFTGemPools(uint256 idx) external view returns (address);

    function allNFTGemPoolsLength() external view returns (uint256);

    function createCustomNFTGemPool(
        bytes memory bytecode,
        string memory gemSymbol,
        string memory gemName
    ) external returns (address payable);

    function createNFTGemPool(
        string memory gemSymbol,
        string memory gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    ) external returns (address payable);

    function addCustomNFTGemPool(
        address poolAddress,
        string memory gemSymbol,
        string memory gemName
    ) external returns (address payable);

    function removeGemPool(uint256 poolHash) external;

    function removeGemPoolAt(uint256 ndx) external;
}
