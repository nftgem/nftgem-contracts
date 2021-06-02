// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

import "../libs/AddressSet.sol";
import "../libs/UInt256Set.sol";
import "../libs/Strings.sol";
import "../libs/SafeMath.sol";
import "./ERC1155Pausable.sol";
import "./ERC1155Holder.sol";
import "../access/Controllable.sol";
import "../interfaces/INFTGemMultiToken.sol";

/**
* @dev ProxyContract placeholder - the proxy delegate
*/
contract OwnableDelegateProxy {}

/**
* @dev a registry of proxies
*/
contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
* @dev a mock object for testing
*/
contract MockProxyRegistry {
    function proxies(address input) external pure returns (address) {
        return input;
    }
}

/**
* @dev the primary multitoken contract
*/
contract NFTGemMultiToken is ERC1155Pausable, ERC1155Holder, INFTGemMultiToken, Controllable {
    using AddressSet for AddressSet.Set;
    using UInt256Set for UInt256Set.Set;

    using SafeMath for uint256;
    using Strings for string;

    // Opensea's proxy registry address.
    address private constant OPENSEA_REGISTRY_ADDRESS = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;

    AddressSet.Set private proxyRegistries;
    address private registryManager;

    // total balance per token id
    mapping(uint256 => uint256) private _totalBalances;
    // time-locked tokens
    mapping(address => mapping(uint256 => uint256)) private _tokenLocks;

    // lists of held tokens by user
    mapping(address => UInt256Set.Set) private _heldTokens;
    // list of token holders
    mapping(uint256 => AddressSet.Set) private _tokenHolders;

    // token types and token pool addresses, to link the multitoken to the tokens created on it
    mapping(uint256 => INFTGemMultiToken.TokenType) private _tokenTypes;
    mapping(uint256 => address) private _tokenPools;

    /**
     * @dev Contract initializer.
     */
    constructor() ERC1155("https://metadata.nftgem.host/") {
        _addController(msg.sender);
        registryManager = msg.sender;
    }

    /**
     * @dev timelock the tokens from moving until the given time
     */
    function lock(uint256 token, uint256 timestamp) external override {
        require(_tokenLocks[_msgSender()][token] < timestamp, "ALREADY_LOCKED");
        _tokenLocks[_msgSender()][token] = timestamp;
    }

    /**
     * @dev unlock time for token / id
     */
    function unlockTime(address account, uint256 token) external view override returns (uint256 theTime) {
        theTime = _tokenLocks[account][token];
    }

    /**
     * @dev Returns the metadata URI for this token type
     */
    function uri(uint256 _id) public view override(ERC1155) returns (string memory) {
        require(_totalBalances[_id] != 0, "NFTGemMultiToken#uri: NONEXISTENT_TOKEN");
        return Strings.strConcat(ERC1155Pausable(this).uri(_id), Strings.uint2str(_id));
    }

    /**
     * @dev returns an array of held tokens for the token holder
     */
    function heldTokens(address holder) external view override returns (uint256[] memory) {
        return _heldTokens[holder].keyList;
    }

    /**
     * @dev held token at index for token holder
     */
    function allHeldTokens(address holder, uint256 _idx) external view override returns (uint256) {
        return _heldTokens[holder].keyList[_idx];
    }

    /**
     * @dev Returns the count of held tokens for the token holder
     */
    function allHeldTokensLength(address holder) external view override returns (uint256) {
        return _heldTokens[holder].keyList.length;
    }

    /**
     * @dev Returns an array of token holders for the given token id
     */
    function tokenHolders(uint256 _token) external view override returns (address[] memory) {
        return _tokenHolders[_token].keyList;
    }

    /**
     * @dev  token holder at index for token id
     */
    function allTokenHolders(uint256 _token, uint256 _idx) external view override returns (address) {
        return _tokenHolders[_token].keyList[_idx];
    }

    /**
     * @dev Returns the count of token holders for the held token
     */
    function allTokenHoldersLength(uint256 _token) external view override returns (uint256) {
        return _tokenHolders[_token].keyList.length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function totalBalances(uint256 _id) external view override returns (uint256) {
        return _totalBalances[_id];
    }

    /**
     * @dev Returns proxy registry at index
     */
    function allProxyRegistries(uint256 _idx) external view override returns (address) {
        return proxyRegistries.keyList[_idx];
    }

    /**
     * @dev Returns the registyry manager account
     */
    function getRegistryManager() external view override returns (address) {
        return registryManager;
    }

    /**
     * @dev set the registry manager account
     */
    function setRegistryManager(address newManager) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        require(newManager != address(0), "UNAUTHORIZED");
        registryManager = newManager;
    }

    /**
     * @dev a count of proxy registries
     */
    function allProxyRegistriesLength() external view override returns (uint256) {
        return proxyRegistries.keyList.length;
    }

    /**
     * @dev add a proxy registry to the list
     */
    function addProxyRegistry(address registry) external override {
        require(msg.sender == registryManager || _controllers[msg.sender] == true, "UNAUTHORIZED");
        proxyRegistries.insert(registry);
    }

    /**
     * @dev remove the proxy registry from the list at index
     */
    function removeProxyRegistryAt(uint256 index) external override {
        require(msg.sender == registryManager || _controllers[msg.sender] == true, "UNAUTHORIZED");
        require(index < proxyRegistries.keyList.length, "INVALID_INDEX");
        proxyRegistries.remove(proxyRegistries.keyList[index]);
    }

    /**
     * @dev override base functionality to check proxy registries for approvers
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        for (uint256 i = 0; i < proxyRegistries.keyList.length; i++) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistries.keyList[i]);
            try proxyRegistry.proxies(_owner) returns (OwnableDelegateProxy thePr) {
                if (address(thePr) == _operator) {
                    return true;
                }
            } catch {}
        }
        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /**
     * @dev mint some amount of tokens. Only callable by token owner
     */
    function mint(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyController {
        _mint(account, uint256(tokenHash), amount, "0x0");
    }

    /**
     * @dev mint some amount of tokens to multiple recipients. Only callable by token owner
     */

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    )  external override onlyController {
        _mintBatch(to, ids, amounts, "0x0");
    }

    /**
     * @dev burn some amount of tokens of multiple token types of account. Only callable by token owner
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external override onlyController {
        _burnBatch(account, ids, amounts);
    }

    /**
     * @dev set the data for this tokenhash. points to a token type (1 = claim, 2 = gem) and token pool address
     */
    function setTokenData(
        uint256 tokenHash,
        INFTGemMultiToken.TokenType tokenType,
        address tokenPool
    ) external override onlyController {
        _tokenTypes[tokenHash] = tokenType;
        _tokenPools[tokenHash] = tokenPool;
    }

    /**
     * @dev get the token data for this token tokenhash
     */
    function getTokenData(uint256 tokenHash) external view override returns (INFTGemMultiToken.TokenType tokenType, address tokenPool) {
        tokenType = _tokenTypes[tokenHash];
        tokenPool = _tokenPools[tokenHash];
    }

    /**
     * @dev internal mint overridden to manage token holders and held tokens lists
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override {
        super._mint(account, id, amount, data);
    }

    /**
     * @dev internal minttbatch should account for managing lists
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev burn some amount of tokens. Only callable by token owner
     */
    function burn(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external override onlyController {
        _burn(account, uint256(tokenHash), amount);
    }

    /**
     * @dev internal burn overridden to track lists
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual override {
        super._burn(account, id, amount);
    }

    /**
     * @dev internal burnBatch should account for managing lists
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override {
        super._burnBatch(account, ids, amounts);
    }

    /**
     * @dev we override this method in order to manager the token holder and held token lists
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            // prevent send if tokens are locked
            if (from != address(0)) {
                require(_tokenLocks[from][ids[i]] <= block.timestamp, "TOKEN_LOCKED");
            }

            // if this is not a mint then remove the held token id from lists if
            // this is the last token if this type the sender owns
            if (from != address(0) && balanceOf(from, ids[i]) == amounts[i]) {
                // find and delete the token id from the token holders held tokens
                if (_heldTokens[from].exists(ids[i])) {
                    _heldTokens[from].remove(ids[i]);
                }
                if (_tokenHolders[ids[i]].exists(from)) {
                    _tokenHolders[ids[i]].remove(from);
                }
            }

            // if this is not a burn and receiver does not yet own token then
            // add that account to the token for that id
            if (to != address(0) && balanceOf(to, ids[i]) == 0) {
                // insert the token id from the token holders held tokens
                if (!_heldTokens[to].exists(ids[i])) {
                    _heldTokens[to].insert(ids[i]);
                }
                if (!_tokenHolders[ids[i]].exists(to)) {
                    _tokenHolders[ids[i]].insert(to);
                }
            }

            // inc and dec balances for each token type
            if (from == address(0)) {
                _totalBalances[uint256(ids[i])] = _totalBalances[uint256(ids[i])].add(amounts[i]);
            }
            if (to == address(0)) {
                _totalBalances[uint256(ids[i])] = _totalBalances[uint256(ids[i])].sub(amounts[i]);
            }
        }
    }
}
