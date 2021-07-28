// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../interfaces/IControllable.sol";
import "../pool/NFTComplexGemPool.sol";
import "../pool/ComplexPoolLib.sol";

import "../interfaces/INFTGemPoolFactory.sol";

contract NFTGemPoolFactory is INFTGemPoolFactory {
    mapping(uint256 => address) private _getNFTGemPool;
    address[] private _allNFTGemPools;

    /**
     * @dev get the quantized token for this
     */
    function getNFTGemPool(uint256 _symbolHash)
        external
        view
        override
        returns (address gemPool)
    {
        gemPool = _getNFTGemPool[_symbolHash];
    }

    /**
     * @dev get the quantized token for this
     */
    function nftGemPools() external view override returns (address[] memory) {
        return _allNFTGemPools;
    }

    /**
     * @dev get the quantized token for this
     */
    function allNFTGemPools(uint256 idx)
        external
        view
        override
        returns (address gemPool)
    {
        gemPool = _allNFTGemPools[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allNFTGemPoolsLength() external view override returns (uint256) {
        return _allNFTGemPools.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createNFTGemPool(
        address owner,
        string memory gemSymbol,
        string memory gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    ) external override returns (address payable gemPool) {
        // create the lookup hash for the given symbol
        // and check if it already exists
        bytes32 salt = keccak256(abi.encodePacked(gemSymbol));
        require(_getNFTGemPool[uint256(salt)] == address(0), "GEMPOOL_EXISTS"); // single check is sufficient

        // validation checks to make sure values are sane
        require(ethPrice != 0, "INVALID_PRICE");
        require(minTime != 0, "INVALID_MIN_TIME");
        require(diffstep != 0, "INVALID_DIFFICULTY_STEP");

        // create the gem pool using create2, which lets us determine the
        // address of a gem pool without interacting with the contract itself
        bytes memory bytecode = type(NFTComplexGemPool).creationCode;

        // use create2 to deploy the gem pool contract
        gemPool = payable(Create2.deploy(0, salt, bytecode));

        // set the controller of the gem pool
        IControllable(gemPool).addController(owner);

        // initialize the erc20 contract with the relevant addresses which it proxies
        NFTComplexGemPool(gemPool).initialize(
            gemSymbol,
            gemName,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxMint,
            allowedToken
        );

        // insert the erc20 contract address into lists
        _getNFTGemPool[uint256(salt)] = gemPool;
        _allNFTGemPools.push(gemPool);

        // emit an event about the new pool being created
        emit NFTGemPoolCreated(
            gemPool,
            gemSymbol,
            gemName,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxMint,
            allowedToken
        );
    }
}
