// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface INiftyPixContract {
    event NiftyPixDataAdded(uint256 tokenHash, string tokenData);

    event NiftyPixFeesCollected(address receiver, uint256 amount);

    event NiftyPixFeeChanged(uint256 newFee);

    event NiftyPixOwnerChanged(address newOwner);

    function initialized() external view returns (bool);

    function getNiftyPixData(uint256 tokenHash)
        external
        view
        returns (string memory);

    function setNiftyPixData(uint256 tokenHash, string memory tokenData)
        external
        payable;

    function hasNiftyPixData(uint256[] memory tokenHashes)
        external
        view
        returns (bool[] memory);

    function getNiftyPixTokenHashes() external view returns (uint256[] memory);

    function getFeesBalance() external view returns (uint256);

    function collectFees(address payable receiver) external;

    function setMintingFee(uint256 newFee) external;

    function getMintingFee() external view returns (uint256);

    function nftGemPoolAddresses() external view returns (address[] memory);

    function nftGemTokenAddress() external view returns (address);

    function addNftGemPool(address theAddress) external;

    function removeNftGemPool(address theAddress) external;


}
