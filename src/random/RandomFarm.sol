// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IRandomFarm.sol";

import "../access/Controllable.sol";

/**
 * @dev A randomness farm. It does what it says - it farms randomness that
 * is provided by the user into usable randomness by other contracts.
 */
contract RandomFarm is IRandomFarm, Initializable {
    uint256 private randomSeed;
    mapping(address => uint256) private salt;

    function initialize(uint256 seed) external override initializer {
        randomSeed = seed;
    }

    function addRandomness(uint256 randomness) external override {
        randomSeed = uint256(
            keccak256(abi.encodePacked(randomSeed, randomness))
        );
    }

    function getRandomBytes(uint8 amount)
        external
        override
        returns (bytes32[] memory _randomBytes)
    {
        _randomBytes = new bytes32[](amount);
        for (uint8 i = 0; i < amount; i++) {
            _randomBytes[i] = _randomByte32();
        }
    }

    function getRandomUints(uint8 amount)
        external
        override
        returns (uint256[] memory _randomUints)
    {
        _randomUints = new uint256[](amount);
        for (uint8 i = 0; i < amount; i++) {
            _randomUints[i] = _randomUint();
        }
    }

    function _randomByte32() internal returns (bytes32 _bytes32) {
        _bytes32 = bytes32(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    randomSeed,
                    tx.origin,
                    salt[tx.origin]++
                )
            )
        );
    }

    function _randomUint() internal returns (uint256 _uint) {
        _uint = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    randomSeed,
                    tx.origin,
                    salt[tx.origin]++
                )
            )
        );
    }

    function getRandomNumber(uint256 min, uint256 max)
        external
        override
        returns (uint256)
    {
        return min + (_randomUint() % (max - min));
    }
}

contract RandomFarmer is IRandomFarmer, Controllable {
    IRandomFarm private farm;

    constructor() {
        _addController(msg.sender);
    }

    function setFarm(address _farm) public onlyController {
        farm = IRandomFarm(_farm);
    }

    function getFarm() public view returns (address _farm) {
        _farm = address(farm);
    }

    function getRandomBytes(uint8 amount)
        external
        override
        returns (bytes32[] memory)
    {
        return farm.getRandomBytes(amount);
    }

    function getRandomUints(uint8 amount)
        external
        override
        returns (uint256[] memory)
    {
        return farm.getRandomUints(amount);
    }

    function getRandomNumber(uint256 min, uint256 max)
        external
        override
        returns (uint256)
    {
        return farm.getRandomNumber(min, max);
    }
}
