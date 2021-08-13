// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/INFTComplexGemPoolData.sol";
import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INiftyPixContract.sol";

contract NiftyPixContract is INiftyPixContract, Initializable, Ownable {
    mapping(uint256 => string) private niftyPixMapping;
    mapping(uint256 => address) private niftyPixGemPool;
    uint256[] private niftyPixHashes;

    uint256 private mintingFee;

    address[] private nftGemPools;
    address private multiToken;

    modifier isInitialized() {
        require(
            nftGemPools.length != 0 && multiToken != address(0),
            "Not initialized"
        );
        _;
    }

    function initialize(
        address _nftGemPool,
        address _multiToken,
        uint256 _mintingFee
    ) external initializer {
        nftGemPools.push(_nftGemPool);
        multiToken = _multiToken;
        mintingFee = _mintingFee;
    }

    function initialized() external view override returns (bool) {
        return nftGemPools.length != 0 && multiToken != address(0);
    }

    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
        emit NiftyPixOwnerChanged(newOwner);
    }

    function getNiftyPixData(uint256 tokenHash)
        external
        view
        override
        returns (string memory)
    {
        return niftyPixMapping[tokenHash];
    }

    function _findGemPool(uint256 tokenHash) internal view returns (address) {
        for (uint256 i = 0; i < nftGemPools.length; i++) {
            if (
                INFTComplexGemPoolData(nftGemPools[i]).tokenType(tokenHash) ==
                INFTGemMultiToken.TokenType.GEM
            ) return nftGemPools[i];
        }
        return address(0);
    }

    function setNiftyPixData(uint256 tokenHash, string memory tokenData)
        external
        payable
        override
        isInitialized
    {
        require(msg.value >= mintingFee, "Missing fee");

        require(
            bytes(niftyPixMapping[tokenHash]).length == 0,
            "Niftypix Data already set"
        );
        require(
            IERC1155(multiToken).balanceOf(msg.sender, tokenHash) > 0,
            "Does not own this token"
        );
        address foundGemPool = _findGemPool(tokenHash);
        require(foundGemPool != address(0), "Not a Bitgem Canvas NFT");

        niftyPixMapping[tokenHash] = tokenData;
        niftyPixGemPool[tokenHash] = foundGemPool;
        niftyPixHashes.push(tokenHash);

        emit NiftyPixDataAdded(tokenHash, tokenData);
    }

    function getNiftyPixTokenHashes()
        external
        view
        override
        returns (uint256[] memory)
    {
        return niftyPixHashes;
    }

    function hasNiftyPixData(uint256[] memory tokenHashes)
        external
        view
        override
        returns (bool[] memory result)
    {
        result = new bool[](tokenHashes.length);
        for (uint256 i = 0; i < tokenHashes.length; i++) {
            result[i] = bytes(niftyPixMapping[tokenHashes[i]]).length != 0;
        }
    }

    function nftGemPoolAddresses()
        external
        view
        override
        returns (address[] memory)
    {
        return nftGemPools;
    }

    function nftGemTokenAddress() external view override returns (address) {
        return multiToken;
    }

    function collectFees(address payable receiver) external override onlyOwner {
        uint256 feesAmount = address(this).balance;
        (bool success, ) = receiver.call{value: feesAmount}("");
        require(success, "Fees send failed");
        emit NiftyPixFeesCollected(receiver, feesAmount);
    }

    function addNftGemPool(address theAddress) external override onlyOwner {
        // require the address to not be zero
        require(theAddress != address(0), "Address is zero");
        for (uint256 i = 0; i < nftGemPools.length; i++) {
            if (nftGemPools[i] == theAddress) return;
        }
        // add the address to the array
        nftGemPools.push(theAddress);
    }

    function removeNftGemPool(address theAddress) external override onlyOwner {
        // require the address to not be zero
        require(theAddress != address(0), "Address is zero");
        for (uint256 i = 0; i < nftGemPools.length; i++) {
            if (nftGemPools[i] == theAddress) {
                if (nftGemPools.length > 1) {
                    nftGemPools[i] = nftGemPools[nftGemPools.length - 1];
                }
                nftGemPools.pop();
            }
        }
    }

    function setMintingFee(uint256 newFee) external override onlyOwner {
        mintingFee = newFee;
        emit NiftyPixFeeChanged(newFee);
    }

    function getMintingFee() external view override returns (uint256) {
        return mintingFee;
    }

    function getFeesBalance() external view override returns (uint256) {
        return address(this).balance;
    }
}
