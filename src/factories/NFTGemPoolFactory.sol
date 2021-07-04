// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "../access/Controllable.sol";
import "../pool/NFTComplexGemPool.sol";
import "../pool/ComplexPoolLib.sol";

import "../interfaces/INFTGemPoolFactory.sol";

contract NFTGemPoolFactory is Controllable, INFTGemPoolFactory {
    address private operator;

    mapping(uint256 => address) private _getNFTGemPool;
    address[] private _allNFTGemPools;

    constructor() {
        _addController(msg.sender);
    }

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
    function createCustomNFTGemPool(
        bytes memory bytecode,
        string memory gemSymbol,
        string memory gemName
    ) external override onlyController returns (address payable gemPool) {
        bytes32 salt = keccak256(abi.encodePacked(gemSymbol));
        require(_getNFTGemPool[uint256(salt)] == address(0), "GEMPOOL_EXISTS"); // single check is sufficient

        // use create2 to deploy the quantized erc20 contract
        gemPool = payable(Create2.deploy(0, salt, bytecode));

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getNFTGemPool[uint256(salt)] = gemPool;
        _allNFTGemPools.push(gemPool);

        // emit an event about the new pool being created
        emit CustomNFTGemPoolCreated(gemPool, gemSymbol, gemName);
    }

    /**
     * @dev add an existing gem pool to factory (for migrations)
     */
    function addCustomNFTGemPool(
        address poolAddress,
        string memory gemSymbol,
        string memory gemName
    ) external override onlyController returns (address payable gemPool) {
        bytes32 salt = keccak256(abi.encodePacked(gemSymbol));
        require(_getNFTGemPool[uint256(salt)] == address(0), "GEMPOOL_EXISTS"); // single check is sufficient

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getNFTGemPool[uint256(salt)] = poolAddress;
        _allNFTGemPools.push(poolAddress);

        // return the address that was passed in
        gemPool = payable(poolAddress);

        // emit an event about the new pool being created
        emit CustomNFTGemPoolCreated(gemPool, gemSymbol, gemName);
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createNFTGemPool(
        string memory gemSymbol,
        string memory gemName,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    ) external override onlyController returns (address payable gemPool) {
        bytes32 salt = keccak256(abi.encodePacked(gemSymbol));
        require(_getNFTGemPool[uint256(salt)] == address(0), "GEMPOOL_EXISTS"); // single check is sufficient

        // validation checks to make sure values are sane
        require(ethPrice != 0, "INVALID_PRICE");
        require(minTime != 0, "INVALID_MIN_TIME");
        require(diffstep != 0, "INVALID_DIFFICULTY_STEP");

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(NFTComplexGemPool).creationCode;

        // use create2 to deploy the quantized erc20 contract
        gemPool = payable(Create2.deploy(0, salt, bytecode));

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

    /**
     * @dev remove a gem pool from the list using its symbol hash
     */
    function removeGemPool(uint256 poolHash) external override onlyController {
        address oldPool = _getNFTGemPool[poolHash];
        delete _getNFTGemPool[poolHash];
        for (uint256 i = 0; i < _allNFTGemPools.length; i++) {
            if (_allNFTGemPools[i] == oldPool) {
                if (_allNFTGemPools.length == 1) {
                    delete _allNFTGemPools;
                } else {
                    _allNFTGemPools[i] ==
                        _allNFTGemPools[_allNFTGemPools.length - 1];
                    delete _allNFTGemPools[_allNFTGemPools.length - 1];
                }
            }
        }
    }

    /**
     * @dev remove a gem pool from the list using its index into pools array
     */
    function removeGemPoolAt(uint256 ndx) external override onlyController {
        require(_allNFTGemPools.length > ndx, "INDEX_OUT_OF_RANGE");
        if (_allNFTGemPools.length == 1) {
            delete _allNFTGemPools;
        } else {
            _allNFTGemPools[ndx] == _allNFTGemPools[_allNFTGemPools.length - 1];
            delete _allNFTGemPools[_allNFTGemPools.length - 1];
        }
    }
}
