// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/utils/Create2.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../lootbox/LootboxContract.sol";

import "../interfaces/ILootbox.sol";

import "../interfaces/ILootboxData.sol";

import "../interfaces/ILootboxFactory.sol";

import "../access/Controllable.sol";

contract LootboxFactory is ILootboxFactory, Controllable, Initializable {
    ILootboxData internal _lootboxData;

    constructor() {
        _addController(msg.sender);
    }

    modifier initialized() {
        require(
            address(_lootboxData) != address(0),
            "Lootbox is not initialized"
        );
        _;
    }

    /**
     * @dev contract initialiser - set the data object
     */
    function initialize(address __data) external override initializer {
        require(
            IControllable(__data).isController(address(this)) == true,
            "Lootbox data must be controlled by this lootbox factory"
        );
        _lootboxData = ILootboxData(__data);
    }

    function isInitialized() external view returns (bool) {
        return address(_lootboxData) != address(0);
    }

    /**
     * @dev get a lootbox
     */
    function getLootbox(uint256 _symbolHash)
        external
        view
        override
        initialized
        returns (address _lootbox)
    {
        _lootbox = _lootboxData.getLootboxBySymbol(_symbolHash).contractAddress;
    }

    /**
     * @dev get the quantized token for this
     */
    function lootboxes()
        external
        view
        override
        initialized
        returns (ILootbox.Lootbox[] memory _all)
    {
        _all = _lootboxData.lootboxes();
    }

    /**
     * @dev get the quantized token for this
     */
    function allLootboxes(uint256 idx)
        external
        view
        override
        initialized
        returns (address _lootbox)
    {
        _lootbox = _lootboxData.allLootboxes(idx).contractAddress;
    }

    /**
     * @dev number of lootboxes
     */
    function allLootboxesLength()
        external
        view
        override
        initialized
        returns (uint256 _len)
    {
        _len = _lootboxData.allLootboxesLength();
    }

    /**
     * @dev deploy a new lootbox using create2
     */
    function createLootbox(address owner, ILootbox.Lootbox memory _lootbox)
        external
        override
        initialized
        returns (address payable Lootbox)
    {
        // create the lookup hash for the given symbol
        // and check if it already exists
        bytes32 salt = keccak256(abi.encodePacked(_lootbox.symbol));
        require(
            _lootboxData.getLootboxBySymbol(uint256(salt)).contractAddress ==
                address(0),
            "Lootbox EXISTS"
        ); // single check is sufficient

        // TODO: validation checks on the incoming Lootbox data

        // create the gem pool using create2, which lets us determine the
        // address of a gem pool without interacting with the contract itself
        bytes memory bytecode = type(LootboxContract).creationCode;

        // use create2 to deploy the gem pool contract
        Lootbox = payable(Create2.deploy(0, salt, bytecode));

        // set the controller of the lootbox
        IControllable(Lootbox).addController(owner);
        IControllable(address(_lootboxData)).addController(Lootbox);

        ILootbox(Lootbox).initialize(address(_lootboxData), _lootbox);
        _lootbox.contractAddress = address(Lootbox);

        // insert the erc20 contract address into lists
        _lootboxData.addLootbox(_lootbox);

        // emit an event about the new pool being created
        emit LootboxCreated(
            _lootbox.lootboxHash,
            _lootbox.contractAddress,
            _lootbox
        );
    }

    function migrate(address migrateTo) external initialized onlyController {
        Controllable(address(_lootboxData)).addController(migrateTo);
        LootboxFactory(migrateTo).initialize(address(_lootboxData));
        selfdestruct(payable(migrateTo));
    }
}
