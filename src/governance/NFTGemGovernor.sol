// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../access/Controllable.sol";

import "../interfaces/INFTGemMultiToken.sol";
import "../interfaces/IProposalFactory.sol";
import "../interfaces/IProposal.sol";
import "../interfaces/INFTComplexGemPool.sol";
import "../interfaces/INFTGemGovernor.sol";
import "../interfaces/INFTGemFeeManager.sol";
import "../interfaces/IProposalData.sol";

import "../governance/GovernanceLib.sol";
import "../governance/ProposalsLib.sol";

contract NFTGemGovernor is Controllable, INFTGemGovernor {
    address private multitoken;
    address private factory;
    address private feeTracker;
    address private proposalFactory;
    address private swapHelper;

    bool private _initialized;

    uint256 private constant GOVERNANCE = 0;
    uint256 private constant GOV_TOKEN_INITIAL = 500000;

    bool private governanceIssued;
    bool private fuelIssued;

    /**
     * @dev contract controller
     */
    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev init this smart contract
     */
    function initialize(
        address _multitoken,
        address _factory,
        address _feeTracker,
        address _proposalFactory,
        address _swapHelper
    ) external override onlyController {
        multitoken = _multitoken;
        factory = _factory;
        feeTracker = _feeTracker;
        proposalFactory = _proposalFactory;
        swapHelper = _swapHelper;
        _initialized = true;
    }

    /**
     * @dev set category category
     */
    function setSwapHelper(address a) external onlyController {
        swapHelper = a;
    }

    /**
     * @dev set category category
     */
    function setFactory(address a) external onlyController {
        factory = a;
    }

    /**
     * @dev set category category
     */
    function setProposalFactory(address a) external onlyController {
        proposalFactory = a;
    }

    /**
     * @dev set category category
     */
    function setMultitoken(address a) external onlyController {
        multitoken = a;
    }

    /**
     * @dev set category category
     */
    function setFeeTracker(address a) external onlyController {
        feeTracker = a;
    }

    /**
     * @dev is the contract initialized
     */
    function initialized() external view override returns (bool) {
        return _initialized;
    }

    /**
     * @dev create proposal vote tokens
     */
    function createProposalVoteTokens(uint256 proposalHash)
        external
        override
        onlyController
    {
        GovernanceLib.createProposalVoteTokens(multitoken, proposalHash);
    }

    /**
     * @dev destroy proposal vote tokens
     */
    function destroyProposalVoteTokens(uint256 proposalHash)
        external
        override
        onlyController
    {
        GovernanceLib.destroyProposalVoteTokens(multitoken, proposalHash);
    }

    /**
     * @dev execute proposal
     */
    function executeProposal(address propAddress)
        external
        override
        onlyController
    {
        ProposalsLib.executeProposal(feeTracker, propAddress);
    }

    /**
     * @dev issue initial governance tokens
     */
    function issueInitialGovernanceTokens(address receiver) external override {
        require(!governanceIssued, "ALREADY_ISSUED");
        INFTGemMultiToken(multitoken).mint(
            receiver,
            GOVERNANCE,
            GOV_TOKEN_INITIAL
        );
        governanceIssued = true;
        emit GovernanceTokenIssued(receiver, GOV_TOKEN_INITIAL);
    }

    /**
     * @dev create a new pool - public, only callable by a controller of this contract
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
        pool = GovernanceLib.createPool(
            factory,
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
        associatePool(msg.sender, msg.sender, pool);
    }

    /**
     * @dev associate the pool with its relations
     */
    function associatePool(
        address creator,
        address funder,
        address pool
    ) internal {
        IControllable(multitoken).addController(pool);
        INFTGemMultiToken(multitoken).addProxyRegistry(pool);
        IControllable(this).addController(pool);
        INFTComplexGemPool(pool).setMultiToken(multitoken);
        INFTComplexGemPool(pool).setSwapHelper(swapHelper);
        INFTComplexGemPool(pool).setGovernor(address(this));
        INFTComplexGemPool(pool).setFeeTracker(feeTracker);
        INFTComplexGemPool(pool).mintGenesisGems(creator, funder);
    }

    /**
     * @dev create a new pool - public, only callable by a controller of this contract
     */
    function createPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external override onlyController returns (address pool) {
        pool = GovernanceLib.createPool(
            factory,
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
        associatePool(
            IProposal(pool).creator(),
            IProposal(pool).funder(),
            pool
        );
    }

    /**
     * @dev create a proposal to change fees for a token / pool
     */
    function createChangeFeeProposal(
        address submitter,
        string memory title,
        address token,
        address pool,
        uint256 feeDivisor
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createChangeFeeProposal(
            token,
            pool,
            feeDivisor
        );
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.CHANGE_FEE,
            title,
            proposal
        );
    }

    /**
     * @dev create a proposal to create a project funding proposal
     */
    function createFundProjectProposal(
        address submitter,
        string memory title,
        address receiver,
        string memory descriptionUrl,
        uint256 ethAmount
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createFundProjectProposal(
            receiver,
            descriptionUrl,
            ethAmount
        );
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.FUND_PROJECT,
            title,
            proposal
        );
    }

    /**
     * @dev create a proposal to update the allowlist of a token/pool
     */
    function createUpdateAllowlistProposal(
        address submitter,
        string memory title,
        address token,
        address pool,
        bool newStatus
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createUpdateAllowlistProposal(
            token,
            pool,
            newStatus
        );
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.UPDATE_ALLOWLIST,
            title,
            proposal
        );
    }
}
