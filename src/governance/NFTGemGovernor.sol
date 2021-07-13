// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/INFTComplexGemPool.sol";
import "../interfaces/INFTGemPoolFactory.sol";
import "../interfaces/INFTGemGovernor.sol";
import "../interfaces/INFTGemFeeManager.sol";

/**
 * @dev The governor contract for the system. Can create system pools (public pools shown on bitgems sites)
 *      and user-owned pools (private pools not shown on the bitgem sites). All  privileged calls are made
 *      through this contract.
 */
contract NFTGemGovernor is Controllable, Initializable, INFTGemGovernor {
    // the multitoken contract
    address private multitoken;
    // the gem pool factory contract
    address private factory;
    // the fee manager contract
    address private feeTracker;
    // the swap manager contract
    address private swapHelper;

    /**
     * @dev contract constructor
     */
    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev init this smart contract. Can only be called once. Sets the related contracts.
     */
    function initialize(
        address _multitoken,
        address _factory,
        address _feeTracker,
        address _swapHelper
    ) public initializer {
        multitoken = _multitoken;
        factory = _factory;
        feeTracker = _feeTracker;
        swapHelper = _swapHelper;
    }

    function initialized() external view override returns (bool) {
        return
            multitoken != address(0x0) &&
            factory != address(0x0) &&
            feeTracker != address(0x0) &&
            swapHelper != address(0x0);
    }

    /**
     * @dev associate the newly-created pool with its relations and give it the privileges
     * @param creator the owner of the pool
     * @param funder the funder of the pool
     * @param pool the pool
     */
    function associatePool(
        address creator,
        address funder,
        address pool
    ) internal {
        IControllable(multitoken).addController(pool);
        IControllable(this).addController(pool);

        //INFTGemMultiToken(multitoken).addProxyRegistry(pool);

        INFTComplexGemPool(pool).setMultiToken(multitoken);
        INFTComplexGemPool(pool).setSwapHelper(swapHelper);
        INFTComplexGemPool(pool).setGovernor(address(this));
        INFTComplexGemPool(pool).setFeeTracker(feeTracker);
        INFTComplexGemPool(pool).mintGenesisGems(creator, funder);
    }

    /**
     * @dev internal gem pool creator method
     */
    function _createPool(
        address owner,
        address funder,
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) internal returns (address pool) {
        // use the gem pool factory to create a new pool
        pool = INFTGemPoolFactory(factory).createNFTGemPool(
            owner,
            symbol,
            name,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,
            allowedToken
        );
        // associate the pool with its relations
        associatePool(owner, funder, pool);
    }

    /**
     * @dev create a new system pool - called by sysadmins to add public pools
     */
    function createSystemPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external override onlyController returns (address pool) {
        pool = _createPool(
            msg.sender,
            msg.sender,
            symbol,
            name,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,
            allowedToken
        );
        // TODO mark the pool as a system pool
    }

    /**
     * @dev create a new pool - public
     */
    function createPool(
        address owner,
        address funder,
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external override returns (address pool) {
        //TODO: we may not need this here at all if a private pool is privately managed anyways
        pool = _createPool(
            owner,
            funder,
            symbol,
            name,
            ethPrice,
            minTime,
            maxTime,
            diffstep,
            maxClaims,
            allowedToken
        );
    }
}
