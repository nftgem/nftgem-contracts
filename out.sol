// Sources flattened with hardhat v2.2.1 https://hardhat.org

// File src/interfaces/IControllable.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IControllable {
    event ControllerAdded(address indexed contractAddress, address indexed controllerAddress);
    event ControllerRemoved(address indexed contractAddress, address indexed controllerAddress);

    function addController(address controller) external;

    function isController(address controller) external view returns (bool);

    function relinquishControl() external;
}


// File src/access/Controllable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

abstract contract Controllable is IControllable {
    mapping(address => bool) _controllers;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "Controllable: caller is not a controller"
        );
        _;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function _addController(address _controller) internal {
        _controllers[_controller] = true;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address _controller) external override onlyController {
        _controllers[_controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address _address) external view override returns (bool allowed) {
        allowed = _controllers[_address];
    }

    /**
     * @dev Check if this address is a controller
     */
    function relinquishControl() external view override onlyController {
        _controllers[msg.sender];
    }
}


// File src/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


// File src/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// File src/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;
/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File src/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}


// File src/interfaces/INFTGemMultiToken.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTGemMultiToken {
    // called by controller to mint a claim or a gem
    function mint(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external;

    // called by controller to burn a claim
    function burn(
        address account,
        uint256 tokenHash,
        uint256 amount
    ) external;

    function allHeldTokens(address holder, uint256 _idx) external view returns (uint256);

    function allHeldTokensLength(address holder) external view returns (uint256);

    function allTokenHolders(uint256 _token, uint256 _idx) external view returns (address);

    function allTokenHoldersLength(uint256 _token) external view returns (uint256);

    function totalBalances(uint256 _id) external view returns (uint256);

    function allProxyRegistries(uint256 _idx) external view returns (address);

    function allProxyRegistriesLength() external view returns (uint256);

    function addProxyRegistry(address registry) external;

    function removeProxyRegistryAt(uint256 index) external;

    function getRegistryManager() external view returns (address);

    function setRegistryManager(address newManager) external;

    function lock(uint256 token, uint256 timeframe) external;

    function unlockTime(address account, uint256 token) external view returns (uint256);
}


// File src/interfaces/INFTGemFeeManager.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface INFTGemFeeManager {

    event DefaultFeeDivisorChanged(address indexed operator, uint256 oldValue, uint256 value);
    event FeeDivisorChanged(address indexed operator, address indexed token, uint256 oldValue, uint256 value);
    event ETHReceived(address indexed manager, address sender, uint256 value);
    event LiquidityChanged(address indexed manager, uint256 oldValue, uint256 value);

    function liquidity(address token) external view returns (uint256);

    function defaultLiquidity() external view returns (uint256);

    function setDefaultLiquidity(uint256 _liquidityMult) external returns (uint256);

    function feeDivisor(address token) external view returns (uint256);

    function defaultFeeDivisor() external view returns (uint256);

    function setFeeDivisor(address token, uint256 _feeDivisor) external returns (uint256);

    function setDefaultFeeDivisor(uint256 _feeDivisor) external returns (uint256);

    function ethBalanceOf() external view returns (uint256);

    function balanceOF(address token) external view returns (uint256);

    function transferEth(address payable recipient, uint256 amount) external;

    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external;

}


// File src/interfaces/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File src/interfaces/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File src/interfaces/IERC1155.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}


// File src/interfaces/INFTGemPool.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface INFTGemPool {

    /**
     * @dev Event generated when an NFT claim is created using ETH
     */
    event NFTGemClaimCreated(address account, address pool, uint256 claimHash, uint256 length, uint256 quantity, uint256 amountPaid);

    /**
     * @dev Event generated when an NFT claim is created using ERC20 tokens
     */
    event NFTGemERC20ClaimCreated(
        address account,
        address pool,
        uint256 claimHash,
        uint256 length,
        address token,
        uint256 quantity,
        uint256 conversionRate
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemClaimRedeemed(
        address account,
        address pool,
        uint256 claimHash,
        uint256 amountPaid,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when an NFT claim is redeemed
     */
    event NFTGemERC20ClaimRedeemed(
        address account,
        address pool,
        uint256 claimHash,
        address token,
        uint256 ethPrice,
        uint256 tokenAmount,
        uint256 feeAssessed
    );

    /**
     * @dev Event generated when a gem is created
     */
    event NFTGemCreated(address account, address pool, uint256 claimHash, uint256 gemHash, uint256 quantity);

    function setMultiToken(address token) external;

    function setGovernor(address addr) external;

    function setFeeTracker(address addr) external;

    function setSwapHelper(address addr) external;

    function mintGenesisGems(address creator, address funder) external;

    function createClaim(uint256 timeframe) external payable;

    function createClaims(uint256 timeframe, uint256 count) external payable;

    function createERC20Claim(address erc20token, uint256 tokenAmount) external;

    function createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) external;

    function collectClaim(uint256 claimHash) external;

    function initialize(
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external;
}


// File src/interfaces/INFTGemGovernor.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface INFTGemGovernor {
    event GovernanceTokenIssued(address indexed receiver, uint256 amount);
    event FeeUpdated(address indexed proposal, address indexed token, uint256 newFee);
    event AllowList(address indexed proposal, address indexed token, bool isBanned);
    event ProjectFunded(address indexed proposal, address indexed receiver, uint256 received);
    event StakingPoolCreated(
        address indexed proposal,
        address indexed pool,
        string symbol,
        string name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,
        address alllowedToken
    );

    function initialize(
        address _multitoken,
        address _factory,
        address _feeTracker,
        address _proposalFactory,
        address _swapHelper
    ) external;

    function createProposalVoteTokens(uint256 proposalHash) external;

    function destroyProposalVoteTokens(uint256 proposalHash) external;

    function executeProposal(address propAddress) external;

    function issueInitialGovernanceTokens(address receiver) external returns (uint256);

    function maybeIssueGovernanceToken(address receiver) external returns (uint256);

    function issueFuelToken(address receiver, uint256 amount) external returns (uint256);

    function createPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external returns (address);

    function createSystemPool(
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,
        address allowedToken
    ) external returns (address);

    function createNewPoolProposal(
        address,
        string memory,
        string memory,
        string memory,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        address
    ) external returns (address);

    function createChangeFeeProposal(
        address,
        string memory,
        address,
        address,
        uint256
    ) external returns (address);

    function createFundProjectProposal(
        address,
        string memory,
        address,
        string memory,
        uint256
    ) external returns (address);

    function createUpdateAllowlistProposal(
        address,
        string memory,
        address,
        address,
        bool
    ) external returns (address);
}


// File src/interfaces/ISwapQueryHelper.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ISwapQueryHelper {

    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function factory() external pure returns (address);

    function COIN() external pure returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function hasPool(address token) external view returns (bool);

    function getReserves(
        address pair
    ) external view returns (uint256, uint256);

    function pairFor(
        address tokenA,
        address tokenB
    ) external pure returns (address);

    function getPathForCoinToToken(address token) external pure returns (address[] memory);

}


// File src/libs/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File src/interfaces/INFTGemPoolData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface INFTGemPoolData {

    // pool is inited with these parameters. Once inited, all
    // but ethPrice are immutable. ethPrice only increases. ONLY UP
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function ethPrice() external view returns (uint256);
    function minTime() external view returns (uint256);
    function maxTime() external view returns (uint256);
    function difficultyStep() external view returns (uint256);
    function maxClaims() external view returns (uint256);

    // these describe the pools created contents over time. This is where
    // you query to get information about a token that a pool created
    function claimedCount() external view returns (uint256);
    function claimAmount(uint256 claimId) external view returns (uint256);
    function claimQuantity(uint256 claimId) external view returns (uint256);
    function mintedCount() external view returns (uint256);
    function totalStakedEth() external view returns (uint256);
    function tokenId(uint256 tokenHash) external view returns (uint256);
    function tokenType(uint256 tokenHash) external view returns (uint8);
    function allTokenHashesLength() external view returns (uint256);
    function allTokenHashes(uint256 ndx) external view returns (uint256);
    function nextClaimHash() external view returns (uint256);
    function nextGemHash() external view returns (uint256);
    function nextGemId() external view returns (uint256);
    function nextClaimId() external view returns (uint256);

    function claimUnlockTime(uint256 claimId) external view returns (uint256);
    function claimTokenAmount(uint256 claimId) external view returns (uint256);
    function stakedToken(uint256 claimId) external view returns (address);

    function allowedTokensLength() external view returns (uint256);
    function allowedTokens(uint256 idx) external view returns (address);
    function isTokenAllowed(address token) external view returns (bool);
    function addAllowedToken(address token) external;
    function removeAllowedToken(address token) external;
}


// File src/pool/NFTGemPoolData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;



contract NFTGemPoolData is INFTGemPoolData, Initializable {
    using SafeMath for uint256;

    // it all starts with a symbol and a nams
    string internal _symbol;
    string internal _name;

    // magic economy numbers
    uint256 internal _ethPrice;
    uint256 internal _minTime;
    uint256 internal _maxTime;
    uint256 internal _diffstep;
    uint256 internal _maxClaims;

    mapping(uint256 => uint8) internal _tokenTypes;
    mapping(uint256 => uint256) internal _tokenIds;
    uint256[] internal _tokenHashes;

    // next ids of things
    uint256 internal _nextGemId;
    uint256 internal _nextClaimId;
    uint256 internal _totalStakedEth;

    // records claim timestamp / ETH value / ERC token and amount sent
    mapping(uint256 => uint256) internal claimLockTimestamps;
    mapping(uint256 => address) internal claimLockToken;
    mapping(uint256 => uint256) internal claimAmountPaid;
    mapping(uint256 => uint256) internal claimQuant;
    mapping(uint256 => uint256) internal claimTokenAmountPaid;

    address[] internal _allowedTokens;
    mapping(address => bool) internal _isAllowedMap;

    constructor() {}

    /**
     * @dev The symbol for this pool / NFT
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev The name for this pool / NFT
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev The ether price for this pool / NFT
     */
    function ethPrice() external view override returns (uint256) {
        return _ethPrice;
    }

    /**
     * @dev min time to stake in this pool to earn an NFT
     */
    function minTime() external view override returns (uint256) {
        return _minTime;
    }

    /**
     * @dev max time to stake in this pool to earn an NFT
     */
    function maxTime() external view override returns (uint256) {
        return _maxTime;
    }

    /**
     * @dev difficulty step increase for this pool.
     */
    function difficultyStep() external view override returns (uint256) {
        return _diffstep;
    }

    /**
     * @dev max claims that can be made on this NFT
     */
    function maxClaims() external view override returns (uint256) {
        return _maxClaims;
    }

    /**
     * @dev number of claims made thus far
     */
    function claimedCount() external view override returns (uint256) {
        return _nextClaimId;
    }

    /**
     * @dev the number of gems minted in this
     */
    function mintedCount() external view override returns (uint256) {
        return _nextGemId;
    }

    /**
     * @dev the number of gems minted in this
     */
    function totalStakedEth() external view override returns (uint256) {
        return _totalStakedEth;
    }

    /**
     * @dev get token type of hash - 1 is for claim, 2 is for gem
     */
    function tokenType(uint256 tokenHash) external view override returns (uint8) {
        return _tokenTypes[tokenHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function tokenId(uint256 tokenHash) external view override returns (uint256) {
        return _tokenIds[tokenHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function allTokenHashesLength() external view override returns (uint256) {
        return _tokenHashes.length;
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function allTokenHashes(uint256 ndx) external view override returns (uint256) {
        return _tokenHashes[ndx];
    }

    /**
     * @dev the external version of the above
     */
    function nextClaimHash() external view override returns (uint256) {
        return _nextClaimHash();
    }

    /**
     * @dev the external version of the above
     */
    function nextGemHash() external view override returns (uint256) {
        return _nextGemHash();
    }

    /**
     * @dev the external version of the above
     */
    function nextClaimId() external view override returns (uint256) {
        return _nextClaimId;
    }

    /**
     * @dev the external version of the above
     */
    function nextGemId() external view override returns (uint256) {
        return _nextGemId;
    }

    /**
     * @dev the external version of the above
     */
    function allowedTokensLength() external view override returns (uint256) {
        return _allowedTokens.length;
    }

    /**
     * @dev the external version of the above
     */
    function allowedTokens(uint256 idx) external view override returns (address) {
        return _allowedTokens[idx];
    }

    /**
     * @dev the external version of the above
     */
    function isTokenAllowed(address token) external view override returns (bool) {
        return _isAllowedMap[token];
    }

    /**
     * @dev the external version of the above
     */
    function addAllowedToken(address token) external override {
        if(!_isAllowedMap[token]) {
            _allowedTokens.push(token);
            _isAllowedMap[token] = true;
        }
    }

    /**
     * @dev the external version of the above
     */
    function removeAllowedToken(address token) external override {
        if(_isAllowedMap[token]) {
            for(uint256 i = 0; i < _allowedTokens.length; i++) {
                if(_allowedTokens[i] == token) {
                   _allowedTokens[i] = _allowedTokens[_allowedTokens.length - 1];
                    delete _allowedTokens[_allowedTokens.length - 1];
                    _isAllowedMap[token] = false;
                    return;
                }
            }
        }
    }

    /**
     * @dev the claim amount for the given claim id
     */
    function claimAmount(uint256 claimHash) external view override returns (uint256) {
        return claimAmountPaid[claimHash];
    }

    /**
     * @dev the claim quantity (count of gems staked) for the given claim id
     */
    function claimQuantity(uint256 claimHash) external view override returns (uint256) {
        return claimQuant[claimHash];
    }

    /**
     * @dev the lock time for this claim. once past lock time a gema is minted
     */
    function claimUnlockTime(uint256 claimHash) external view override returns (uint256) {
        return claimLockTimestamps[claimHash];
    }

    /**
     * @dev claim token amount if paid using erc20
     */
    function claimTokenAmount(uint256 claimHash) external view override returns (uint256) {
        return claimTokenAmountPaid[claimHash];
    }

    /**
     * @dev the staked token if staking with erc20
     */
    function stakedToken(uint256 claimHash) external view override returns (address) {
        return claimLockToken[claimHash];
    }

    /**
     * @dev get token id (serial #) of the given token hash. 0 if not a token, 1 if claim, 2 if gem
     */
    function _addToken(uint256 tokenHash, uint8 tt) internal {
        require(tt == 1 || tt == 2, "INVALID_TOKENTYPE");
        _tokenHashes.push(tokenHash);
        _tokenTypes[tokenHash] = tt;
        _tokenIds[tokenHash] = tt == 1 ? __nextClaimId() : __nextGemId();
        if(tt == 2) {
            _increaseDifficulty();
        }
    }

    /**
     * @dev get the next claim id
     */
    function __nextClaimId() private returns (uint256) {
        uint256 ncId = _nextClaimId;
        _nextClaimId = _nextClaimId.add(1);
        return ncId;
    }

    /**
     * @dev get the next gem id
     */
    function __nextGemId() private returns (uint256) {
        uint256 ncId = _nextGemId;
        _nextGemId = _nextGemId.add(1);
        return ncId;
    }

    /**
     * @dev increase the pool's difficulty by calculating the step increase portion and adding it to the eth price of the market
     */
    function _increaseDifficulty() private {
        uint256 diffIncrease = _ethPrice.div(_diffstep);
        _ethPrice = _ethPrice.add(diffIncrease);
    }

    /**
     * @dev the hash of the next gem to be minted
     */
    function _nextGemHash() internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked("gem", address(this), _nextGemId)));
    }

    /**
     * @dev the hash of the next claim to be minted
     */
    function _nextClaimHash() internal view returns (uint256) {
        return
            (_maxClaims != 0 && _nextClaimId <= _maxClaims) || _maxClaims == 0
                ? uint256(keccak256(abi.encodePacked("claim", address(this), _nextClaimId)))
                : 0;
    }

}


// File src/pool/NFTGemPool.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;









contract NFTGemPool is Initializable, NFTGemPoolData, INFTGemPool {
    using SafeMath for uint256;

    // governor and multitoken target
    address private _multitoken;
    address private _governor;
    address private _feeTracker;
    address private _swapHelper;

    /**
     * @dev initializer called when contract is deployed
     */
    function initialize (
        string memory __symbol,
        string memory __name,
        uint256 __ethPrice,
        uint256 __minTime,
        uint256 __maxTime,
        uint256 __diffstep,
        uint256 __maxClaims,
        address __allowedToken
    ) external override initializer {
        _symbol = __symbol;
        _name = __name;
        _ethPrice = __ethPrice;
        _minTime = __minTime;
        _maxTime = __maxTime;
        _diffstep = __diffstep;
        _maxClaims = __maxClaims;

        if(__allowedToken != address(0)) {
            _allowedTokens.push(__allowedToken);
            _isAllowedMap[__allowedToken] = true;
        }
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setGovernor(address addr) external override {
        require(_governor == address(0), "IMMUTABLE");
        _governor = addr;
    }

    /**
     * @dev set the governor. pool uses the governor to issue gov token issuance requests
     */
    function setFeeTracker(address addr) external override {
        require(_feeTracker == address(0), "IMMUTABLE");
        _feeTracker = addr;
    }

    /**
     * @dev set the multitoken that this pool will mint new tokens on. Must be a controller of the multitoken
     */
    function setMultiToken(address token) external override {
        require(_multitoken == address(0), "IMMUTABLE");
        _multitoken = token;
    }

    /**
     * @dev set the multitoken that this pool will mint new tokens on. Must be a controller of the multitoken
     */
    function setSwapHelper(address helper) external override {
        require(_swapHelper == address(0), "IMMUTABLE");
        _swapHelper = helper;
    }

    /**
     * @dev mint the genesis gems earned by the pools creator and funder
     */
    function mintGenesisGems(address creator, address funder) external override {
        require(_multitoken != address(0), "NO_MULTITOKEN");
        require(creator != address(0) && funder != address(0), "ZERO_DESTINATION");
        require(_nextGemId == 0, "ALREADY_MINTED");

        uint256 gemHash = _nextGemHash();
        INFTGemMultiToken(_multitoken).mint(creator, gemHash, 1);
        _addToken(gemHash, 2);

        gemHash = _nextGemHash();
        INFTGemMultiToken(_multitoken).mint(creator, gemHash, 1);
        _addToken(gemHash, 2);
    }

    /**
     * @dev the external version of the above
     */
    function createClaim(uint256 timeframe) external payable override {
        _createClaim(timeframe);
    }

    /**
     * @dev the external version of the above
     */
    function createClaims(uint256 timeframe, uint256 count) external payable override {
        _createClaims(timeframe, count);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claim(address erc20token, uint256 tokenAmount) external override {
        _createERC20Claim(erc20token, tokenAmount);
    }

    /**
     * @dev create a claim using a erc20 token
     */
    function createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) external override {
        _createERC20Claims(erc20token, tokenAmount, count);
    }


    /**
     * @dev default receive. tries to issue a claim given the received ETH or
     */
    receive() external payable {
        uint256 incomingEth = msg.value;

        // compute the mimimum cost of a claim and revert if not enough sent
        uint256 minClaimCost = _ethPrice.div(_maxTime).mul(_minTime);
        require(incomingEth >= minClaimCost, "INSUFFICIENT_ETH");

        // compute the minimum actual claim time
        uint256 actualClaimTime = _minTime;

        // refund ETH above max claim cost
        if (incomingEth <= _ethPrice)  {
            actualClaimTime = _ethPrice.div(incomingEth).mul(_minTime);
        }

        // create the claim using minimum possible claim time
        _createClaim(actualClaimTime);
    }

    /**
     * @dev attempt to create a claim using the given timeframe
     */
    function _createClaim(uint256 timeframe) internal {
        // minimum timeframe
        require(timeframe >= _minTime, "TIMEFRAME_TOO_SHORT");

        // maximum timeframe
        require((_maxTime != 0 && timeframe <= _maxTime) || _maxTime == 0, "TIMEFRAME_TOO_LONG");

        // cost given this timeframe
        uint256 cost = _ethPrice.mul(_minTime).div(timeframe);
        require(msg.value > cost, "INSUFFICIENT_ETH");

        // get the nest claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(timeframe);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = cost;
        claimQuant[claimHash] = 1;

        // increase the staked eth balance
        _totalStakedEth = _totalStakedEth.add(cost);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, cost);

        emit NFTGemClaimCreated(msg.sender, address(this), claimHash, timeframe, 1, cost);

        if (msg.value > cost) {
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(cost)}("");
            require(success, "REFUND_FAILED");
        }
    }

    /**
     * @dev attempt to create a claim using the given timeframe
     */
    function _createClaims(uint256 timeframe, uint256 count) internal {
        // minimum timeframe
        require(timeframe >= _minTime, "TIMEFRAME_TOO_SHORT");
        // no ETH
        require(msg.value != 0, "ZERO_BALANCE");
        // zero qty
        require(count != 0, "ZERO_QUANTITY");
        // maximum timeframe
        require((_maxTime != 0 && timeframe <= _maxTime) || _maxTime == 0, "TIMEFRAME_TOO_LONG");

        uint256 adjustedBalance = msg.value.div(count);
        // cost given this timeframe

        uint256 cost = _ethPrice.mul(_minTime).div(timeframe);
        require(adjustedBalance >= cost, "INSUFFICIENT_ETH");

        // get the nest claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(timeframe);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = cost.mul(count);
        claimQuant[claimHash] = count;

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, cost);

        emit NFTGemClaimCreated(msg.sender, address(this), claimHash, timeframe, count, cost);

        // increase the staked eth balance
        _totalStakedEth = _totalStakedEth.add(cost.mul(count));

        if (msg.value > cost.mul(count)) {
            (bool success, ) = payable(msg.sender).call{value: msg.value.sub(cost.mul(count))}("");
            require(success, "REFUND_FAILED");
        }
    }

    /**
     * @dev crate a gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function _createERC20Claim(address erc20token, uint256 tokenAmount) internal {
        // must be a valid address
        require(erc20token != address(0), "INVALID_ERC20_TOKEN");

        // token is allowed
        require((_allowedTokens.length > 0 && _isAllowedMap[erc20token]) || _allowedTokens.length == 0, "TOKEN_DISALLOWED");

        // Uniswap pool must exist
        require(ISwapQueryHelper(_swapHelper).hasPool(erc20token) == true, "NO_UNISWAP_POOL");

        // must have an amount specified
        require(tokenAmount >= 0, "NO_PAYMENT_INCLUDED");

        // get a quote in ETH for the given token.
        (uint256 ethereum, uint256 tokenReserve, uint256 ethReserve) = ISwapQueryHelper(_swapHelper).coinQuote(erc20token, tokenAmount);

        // get the min liquidity from fee tracker
        uint256 liquidity = INFTGemFeeManager(_feeTracker).liquidity(erc20token);

        // make sure the convertible amount is has reserves > 100x the token
        require(ethReserve >= ethereum.mul(liquidity), "INSUFFICIENT_ETH_LIQUIDITY");

        // make sure the convertible amount is has reserves > 100x the token
        require(tokenReserve >= tokenAmount.mul(liquidity), "INSUFFICIENT_TOKEN_LIQUIDITY");

        // make sure the convertible amount is less than max price
        require(ethereum <= _ethPrice, "OVERPAYMENT");

        // calculate the maturity time given the converted eth
        uint256 maturityTime = _ethPrice.mul(_minTime).div(ethereum);

        // make sure the convertible amount is less than max price
        require(maturityTime >= _minTime, "INSUFFICIENT_TIME");

        // get the next claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // transfer the caller's ERC20 tokens into the pool
        IERC20(erc20token).transferFrom(msg.sender, address(this), tokenAmount);

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(maturityTime);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = ethereum;
        claimLockToken[claimHash] = erc20token;
        claimTokenAmountPaid[claimHash] = tokenAmount;
        claimQuant[claimHash] = 1;

        _totalStakedEth = _totalStakedEth.add(ethereum);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, ethereum);

        // emit a message indicating that an erc20 claim has been created
        emit NFTGemERC20ClaimCreated(msg.sender, address(this), claimHash, maturityTime, erc20token, 1, ethereum);
    }

    /**
     * @dev crate multiple gem claim using an erc20 token. this token must be tradeable in Uniswap or this call will fail
     */
    function _createERC20Claims(address erc20token, uint256 tokenAmount, uint256 count) internal {
        // must be a valid address
        require(erc20token != address(0), "INVALID_ERC20_TOKEN");

        // token is allowed
        require((_allowedTokens.length > 0 && _isAllowedMap[erc20token]) || _allowedTokens.length == 0, "TOKEN_DISALLOWED");

        // zero qty
        require(count != 0, "ZERO_QUANTITY");

        // Uniswap pool must exist
        require(ISwapQueryHelper(_swapHelper).hasPool(erc20token) == true, "NO_UNISWAP_POOL");

        // must have an amount specified
        require(tokenAmount >= 0, "NO_PAYMENT_INCLUDED");

        // get a quote in ETH for the given token.
        (uint256 ethereum, uint256 tokenReserve, uint256 ethReserve) = ISwapQueryHelper(_swapHelper).coinQuote(
            erc20token,
            tokenAmount.div(count)
        );

        // make sure the convertible amount is has reserves > 100x the token
        require(ethReserve >= ethereum.mul(100).mul(count), "INSUFFICIENT_ETH_LIQUIDITY");

        // make sure the convertible amount is has reserves > 100x the token
        require(tokenReserve >= tokenAmount.mul(100).mul(count), "INSUFFICIENT_TOKEN_LIQUIDITY");

        // make sure the convertible amount is less than max price
        require(ethereum <= _ethPrice, "OVERPAYMENT");

        // calculate the maturity time given the converted eth
        uint256 maturityTime = _ethPrice.mul(_minTime).div(ethereum);

        // make sure the convertible amount is less than max price
        require(maturityTime >= _minTime, "INSUFFICIENT_TIME");

        // get the next claim hash, revert if no more claims
        uint256 claimHash = _nextClaimHash();
        require(claimHash != 0, "NO_MORE_CLAIMABLE");

        // mint the new claim to the caller's address
        INFTGemMultiToken(_multitoken).mint(msg.sender, claimHash, 1);
        _addToken(claimHash, 1);

        // record the claim unlock time and cost paid for this claim
        uint256 _claimUnlockTime = block.timestamp.add(maturityTime);
        claimLockTimestamps[claimHash] = _claimUnlockTime;
        claimAmountPaid[claimHash] = ethereum;
        claimLockToken[claimHash] = erc20token;
        claimTokenAmountPaid[claimHash] = tokenAmount;
        claimQuant[claimHash] = count;

        // increase staked eth amount
        _totalStakedEth = _totalStakedEth.add(ethereum);

        // maybe mint a governance token for the claimant
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, ethereum);

        // emit a message indicating that an erc20 claim has been created
        emit NFTGemERC20ClaimCreated(msg.sender, address(this), claimHash, maturityTime, erc20token, count, ethereum);

        // transfer the caller's ERC20 tokens into the pool
        IERC20(erc20token).transferFrom(msg.sender, address(this), tokenAmount);
    }

    /**
     * @dev collect an open claim (take custody of the funds the claim is redeeemable for and maybe a gem too)
     */
    function collectClaim(uint256 claimHash) external override {
        // validation checks - disallow if not owner (holds coin with claimHash)
        // or if the unlockTime amd unlockPaid data is in an invalid state
        require(IERC1155(_multitoken).balanceOf(msg.sender, claimHash) == 1, "NOT_CLAIM_OWNER");
        uint256 unlockTime = claimLockTimestamps[claimHash];
        uint256 unlockPaid = claimAmountPaid[claimHash];
        require(unlockTime != 0 && unlockPaid > 0, "INVALID_CLAIM");

        // grab the erc20 token info if there is any
        address tokenUsed = claimLockToken[claimHash];
        uint256 unlockTokenPaid = claimTokenAmountPaid[claimHash];

        // check the maturity of the claim - only issue gem if mature
        bool isMature = unlockTime < block.timestamp;

        //  burn claim and transfer money back to user
        INFTGemMultiToken(_multitoken).burn(msg.sender, claimHash, 1);

        // if they used erc20 tokens stake their claim, return their tokens
        if (tokenUsed != address(0)) {
            // calculate fee portion using fee tracker
            uint256 feePortion = 0;
            if (isMature == true) {
                uint256 poolDiv = INFTGemFeeManager(_feeTracker).feeDivisor(address(this));
                uint256 divisor = INFTGemFeeManager(_feeTracker).feeDivisor(tokenUsed);
                uint256 feeNum = poolDiv != divisor ? divisor : poolDiv;
                feePortion = unlockTokenPaid.div(feeNum);
            }
            // assess a fee for minting the NFT. Fee is collectec in fee tracker
            IERC20(tokenUsed).transferFrom(address(this), _feeTracker, feePortion);
            // send the principal minus fees to the caller
            IERC20(tokenUsed).transferFrom(address(this), msg.sender, unlockTokenPaid.sub(feePortion));

            // emit an event that the claim was redeemed for ERC20
            emit NFTGemERC20ClaimRedeemed(
                msg.sender,
                address(this),
                claimHash,
                tokenUsed,
                unlockPaid,
                unlockTokenPaid,
                feePortion
            );
        } else {
            // calculate fee portion using fee tracker
            uint256 feePortion = 0;
            if (isMature == true) {
                uint256 divisor = INFTGemFeeManager(_feeTracker).feeDivisor(address(0));
                feePortion = unlockPaid.div(divisor);
            }
            // transfer the ETH fee to fee tracker
            payable(_feeTracker).transfer(feePortion);
            // transfer the ETH back to user
            payable(msg.sender).transfer(unlockPaid.sub(feePortion));

            // emit an event that the claim was redeemed for ETH
            emit NFTGemClaimRedeemed(msg.sender, address(this), claimHash, unlockPaid, feePortion);
        }

        // deduct the total staked ETH balance of the pool
        _totalStakedEth = _totalStakedEth.sub(unlockPaid);

        // if all this is happening before the unlocktime then we exit
        // without minting a gem because the user is withdrawing early
        if (!isMature) {
            return;
        }

        // get the next gem hash, increase the staking sifficulty
        // for the pool, and mint a gem token back to account
        uint256 nextHash = this.nextGemHash();

        // mint the gem
        INFTGemMultiToken(_multitoken).mint(msg.sender, nextHash, claimQuant[claimHash]);
        _addToken(nextHash, 2);

        // maybe mint a governance token
        INFTGemGovernor(_governor).maybeIssueGovernanceToken(msg.sender);
        INFTGemGovernor(_governor).issueFuelToken(msg.sender, unlockPaid);

        // emit an event about a gem getting created
        emit NFTGemCreated(msg.sender, address(this), claimHash, nextHash, claimQuant[claimHash]);
    }

}


// File src/libs/Create2.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}


// File src/tokens/ERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File src/tokens/ERC20Constructorless.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Constructorless is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance")
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero")
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File src/interfaces/IERC20WrappedGem.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20WrappedGem {
    function wrap(uint256 quantity) external;

    function unwrap(uint256 quantity) external;

    event Wrap(address indexed account, uint256 quantity);
    event Unwrap(address indexed account, uint256 quantity);

    function initialize(
        string memory tokenSymbol,
        string memory tokenName,
        address poolAddress,
        address tokenAddress,
        uint8 decimals
    ) external;
}


// File src/interfaces/IERC1155Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}


// File src/introspection/ERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor() {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}


// File src/tokens/ERC1155Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(
            ERC1155Receiver(address(0)).onERC1155Received.selector ^
                ERC1155Receiver(address(0)).onERC1155BatchReceived.selector
        );
    }
}


// File src/tokens/ERC1155Holder.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}


// File src/tokens/ERC20WrappedGem.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;








contract ERC20WrappedGem is ERC20Constructorless, ERC1155Holder, IERC20WrappedGem, Initializable {
    using SafeMath for uint256;

    address private token;
    address private pool;
    uint256 private rate;

    uint256[] private ids;
    uint256[] private amounts;

    function initialize(
        string memory name,
        string memory symbol,
        address gemPool,
        address gemToken,
        uint8 decimals
    ) external override initializer {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        token = gemToken;
        pool = gemPool;
    }

    function _transferERC1155(
        address from,
        address to,
        uint256 quantity
    ) internal {
        uint256 tq = quantity;
        delete ids;
        delete amounts;

        uint256 i = INFTGemMultiToken(token).allHeldTokensLength(from);
        require(i > 0, "INSUFFICIENT_GEMS");

        for (; i >= 0 && tq > 0; i = i.sub(1)) {
            uint256 tokenHash = INFTGemMultiToken(token).allHeldTokens(from, i);
            if (INFTGemPoolData(pool).tokenType(tokenHash) == 2) {
                uint256 oq = IERC1155(token).balanceOf(from, tokenHash);
                uint256 toTransfer = oq > tq ? tq : oq;
                ids.push(tokenHash);
                amounts.push(toTransfer);
                tq = tq.sub(toTransfer);
            }
            if (i == 0) break;
        }

        require(tq == 0, "INSUFFICIENT_GEMS");

        IERC1155(token).safeBatchTransferFrom(from, to, ids, amounts, "");
    }

    function wrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");

        _transferERC1155(msg.sender, address(this), quantity);
        _mint(msg.sender, quantity.mul(10**decimals()));
        emit Wrap(msg.sender, quantity);
    }

    function unwrap(uint256 quantity) external override {
        require(quantity != 0, "ZERO_QUANTITY");
        require(balanceOf(msg.sender).mul(10**decimals()) >= quantity, "INSUFFICIENT_QUANTITY");

        _transferERC1155(address(this), msg.sender, quantity);
        _burn(msg.sender, quantity.mul(10**decimals()));
        emit Unwrap(msg.sender, quantity);
    }
}


// File src/interfaces/IERC20GemTokenFactory.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IERC20GemTokenFactory {
    /**
     * @dev emitted when a new gem pool has been added to the system
     */
    event ERC20GemTokenCreated(
        address tokenAddress,
        address poolAddress,
        string tokenSymbol,
        string poolSymbol
    );

    function getItem(uint256 _symbolHash) external view returns (address);

    function allItems(uint256 idx) external view returns (address);

    function allItemsLength() external view returns (uint256);

    function createItem(
        string memory tokenSymbol,
        string memory tokenName,
        address poolAddress,
        address tokenAddress,
        uint8 decimals
    ) external returns (address payable);
}


// File src/factories/ERC20GemTokenFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;








contract ERC20GemTokenFactory is Controllable, IERC20GemTokenFactory {
    address private operator;

    mapping(uint256 => address) private _getItem;
    address[] private _allItems;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev get the quantized token for this
     */
    function getItem(uint256 _symbolHash) external view override returns (address gemPool) {
        gemPool = _getItem[_symbolHash];
    }

    /**
     * @dev get the quantized token for this
     */
    function allItems(uint256 idx) external view override returns (address gemPool) {
        gemPool = _allItems[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allItemsLength() external view override returns (uint256) {
        return _allItems.length;
    }

    /**
     * @dev deploy a new erc20 token using create2
     */
    function createItem(
        string memory tokenSymbol,
        string memory tokenName,
        address poolAddress,
        address tokenAddress,
        uint8 decimals
    ) external override onlyController returns (address payable gemToken) {
        bytes32 salt = keccak256(abi.encodePacked(tokenSymbol));
        require(_getItem[uint256(salt)] == address(0), "GEMTOKEN_EXISTS"); // single check is sufficient
        require(poolAddress != address(0), "INVALID_POOL");

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(ERC20WrappedGem).creationCode;

        // use create2 to deploy the quantized erc20 contract
        gemToken = payable(Create2.deploy(0, salt, bytecode));

        // initialize the erc20 contract with the relevant addresses which it proxies
        IERC20WrappedGem(gemToken).initialize(tokenSymbol, tokenName, poolAddress, tokenAddress, decimals);

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getItem[uint256(salt)] = gemToken;
        _allItems.push(gemToken);

        // emit an event about the new pool being created
        emit ERC20GemTokenCreated(gemToken, poolAddress, tokenSymbol, ERC20(gemToken).symbol());
    }
}


// File src/interfaces/INFTGemPoolFactory.sol

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
        string gemSymbol,
        string gemName,
        uint256 ethPrice,
        uint256 mintTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxMint,
        address allowedToken
    );

    function getNFTGemPool(uint256 _symbolHash) external view returns (address);

    function allNFTGemPools(uint256 idx) external view returns (address);

    function allNFTGemPoolsLength() external view returns (uint256);

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
}


// File src/factories/NFTGemPoolFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;




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
    function getNFTGemPool(uint256 _symbolHash) external view override returns (address gemPool) {
        gemPool = _getNFTGemPool[_symbolHash];
    }

    /**
     * @dev get the quantized token for this
     */
    function allNFTGemPools(uint256 idx) external view override returns (address gemPool) {
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
        bytes memory bytecode = type(NFTGemPool).creationCode;

        // use create2 to deploy the quantized erc20 contract
        gemPool = payable(Create2.deploy(0, salt, bytecode));

        // initialize the erc20 contract with the relevant addresses which it proxies
        NFTGemPool(gemPool).initialize(gemSymbol, gemName, ethPrice, minTime, maxTime, diffstep, maxMint, allowedToken);

        // insert the erc20 contract address into lists - one that maps source to quantized,
        _getNFTGemPool[uint256(salt)] = gemPool;
        _allNFTGemPools.push(gemPool);

        // emit an event about the new pool being created
        emit NFTGemPoolCreated(gemSymbol, gemName, ethPrice, minTime, maxTime, diffstep, maxMint, allowedToken);
    }
}


// File src/interfaces/IProposal.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IProposal {
    enum ProposalType {CREATE_POOL, FUND_PROJECT, CHANGE_FEE, UPDATE_ALLOWLIST}

    enum ProposalStatus {NOT_FUNDED, ACTIVE, PASSED, FAILED, EXECUTED, CLOSED}

    event ProposalCreated(address creator, address pool, uint256 proposalHash);

    event ProposalExecuted(uint256 proposalHash);

    event ProposalClosed(uint256 proposalHash);

    function creator() external view returns (address);

    function title() external view returns (string memory);

    function funder() external view returns (address);

    function expiration() external view returns (uint256);

    function status() external view returns (ProposalStatus);

    function proposalData() external view returns (address);

    function proposalType() external view returns (ProposalType);

    function setMultiToken(address token) external;

    function setGovernor(address gov) external;

    function fund() external payable;

    function execute() external;

    function close() external;

    function initialize(
        address,
        string memory,
        address,
        ProposalType
    ) external;
}


// File src/interfaces/IProposalFactory.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface for a Bitgem staking pool
 */
interface IProposalFactory {
    /**
     * @dev emitted when a new gem pool proposal has been added to the system
     */
    event ProposalCreated(address creator, uint256 proposalType, address proposal);

    event ProposalFunded(uint256 indexed proposalHash, address indexed funder, uint256 expDate);

    event ProposalExecuted(uint256 indexed proposalHash, address pool);

    event ProposalClosed(uint256 indexed proposalHash, address pool);

    function getProposal(uint256 _symbolHash) external view returns (address);

    function allProposals(uint256 idx) external view returns (address);

    function allProposalsLength() external view returns (uint256);

    function createProposal(
        address submitter,
        string memory title,
        address proposalData,
        IProposal.ProposalType proposalType
    ) external returns (address payable);
}


// File src/interfaces/IProposalData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface ICreatePoolProposalData {
    function data()
        external
        view
        returns (
            string memory,
            string memory,

            uint256,
            uint256,
            uint256,
            uint256,
            uint256,

            address
        );
}

interface IChangeFeeProposalData {
    function data()
        external
        view
        returns (
            address,
            address,
            uint256
        );
}

interface IFundProjectProposalData {
    function data()
        external
        view
        returns (
            address,
            string memory,
            uint256
        );
}

interface IUpdateAllowlistProposalData {
    function data()
        external
        view
        returns (
            address,
            address,
            bool
        );
}


// File src/governance/GovernanceLib.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;







library GovernanceLib {

    // calculates the CREATE2 address for the quantized erc20 without making any external calls
    function addressOfPropoal(
        address factory,
        address submitter,
        string memory title
    ) public pure returns (address govAddress) {
        govAddress = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(submitter, title)),
                        hex"74f827a6bb3b7ed4cd86bd3c09b189a9496bc40d83635649e1e4df1c4e836ebf" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev create vote tokens to vote on given proposal
     */
    function createProposalVoteTokens(address multitoken, uint256 proposalHash) external {
        for (uint256 i = 0; i < INFTGemMultiToken(multitoken).allTokenHoldersLength(0); i++) {
            address holder = INFTGemMultiToken(multitoken).allTokenHolders(0, i);
            INFTGemMultiToken(multitoken).mint(holder, proposalHash,
                IERC1155(multitoken).balanceOf(holder, 0)
            );
        }
    }

    /**
     * @dev destroy the vote tokens for the given proposal
     */
    function destroyProposalVoteTokens(address multitoken, uint256 proposalHash) external {
        for (uint256 i = 0; i < INFTGemMultiToken(multitoken).allTokenHoldersLength(0); i++) {
            address holder = INFTGemMultiToken(multitoken).allTokenHolders(0, i);
            INFTGemMultiToken(multitoken).burn(holder, proposalHash,
                IERC1155(multitoken).balanceOf(holder, proposalHash)
            );
        }
    }

        /**
     * @dev execute craete pool proposal
     */
    function execute(
        address factory,
        address proposalAddress) public returns (address newPool) {

        // get the data for the new pool from the proposal
        address proposalData = IProposal(proposalAddress).proposalData();

        (
            string memory symbol,
            string memory name,

            uint256 ethPrice,
            uint256 minTime,
            uint256 maxTime,
            uint256 diffStep,
            uint256 maxClaims,

            address allowedToken
        ) = ICreatePoolProposalData(proposalData).data();

        // create the new pool
        newPool = createPool(
            factory,

            symbol,
            name,

            ethPrice,
            minTime,
            maxTime,
            diffStep,
            maxClaims,

            allowedToken
        );
    }

    /**
     * @dev create a new pool
     */
    function createPool(
        address factory,

        string memory symbol,
        string memory name,

        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffstep,
        uint256 maxClaims,

        address allowedToken
    ) public returns (address pool) {
        pool = INFTGemPoolFactory(factory).createNFTGemPool(
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


// File src/governance/Proposal.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;









contract Proposal is Initializable, ERC1155Holder, IProposal {
    using SafeMath for uint256;

    uint256 private constant MONTH = 2592000;
    uint256 private constant PROPOSAL_COST = 1 ether;

    string private _title;
    address private _creator;
    address private _funder;
    address private _multitoken;
    address private _governor;
    uint256 private _expiration;

    address private _proposalData;
    ProposalType private _proposalType;

    bool private _funded;
    bool private _executed;
    bool private _closed;

    constructor() {}

    function initialize(
        address __creator,
        string memory __title,
        address __proposalData,
        ProposalType __proposalType
    ) external override initializer {
        _title = __title;
        _creator = __creator;
        _proposalData = __proposalData;
        _proposalType = __proposalType;
    }

    function setMultiToken(address token) external override {
        require(_multitoken == address(0), "IMMUTABLE");
        _multitoken = token;
    }

    function setGovernor(address gov) external override {
        require(_governor == address(0), "IMMUTABLE");
        _governor = gov;
    }

    function title() external view override returns (string memory) {
        return _title;
    }

    function creator() external view override returns (address) {
        return _creator;
    }

    function funder() external view override returns (address) {
        return _creator;
    }

    function expiration() external view override returns (uint256) {
        return _expiration;
    }

    function _status() internal view returns (ProposalStatus curCtatus) {
        curCtatus = ProposalStatus.ACTIVE;
        if (!_funded) {
            curCtatus = ProposalStatus.NOT_FUNDED;
        } else if (_executed) {
            curCtatus = ProposalStatus.EXECUTED;
        } else if (_closed) {
            curCtatus = ProposalStatus.CLOSED;
        } else {
            uint256 totalVotesSupply = INFTGemMultiToken(_multitoken).totalBalances(uint256(address(this)));
            uint256 totalVotesInFavor = IERC1155(_multitoken).balanceOf(address(this), uint256(address(this)));
            uint256 votesToPass = totalVotesSupply.div(2).add(1);
            curCtatus = totalVotesInFavor >= votesToPass ? ProposalStatus.PASSED : ProposalStatus.ACTIVE;
            if (block.timestamp > _expiration) {
                curCtatus = totalVotesInFavor >= votesToPass ? ProposalStatus.PASSED : ProposalStatus.FAILED;
            }
        }

    }

    function status() external view override returns (ProposalStatus curCtatus) {
        curCtatus = _status();
    }

    function proposalData() external view override returns (address) {
        return _proposalData;
    }

    function proposalType() external view override returns (ProposalType) {
        return _proposalType;
    }

    function fund() external payable override {
        // ensure we cannot fund while in an invalida state
        require(!_funded, "ALREADY_FUNDED");
        require(!_closed, "ALREADY_CLOSED");
        require(!_executed, "ALREADY_EXECUTED");
        require(msg.value >= PROPOSAL_COST, "MISSING_FEE");

        // proposal is now funded and clock starts ticking
        _funded = true;
        _expiration = block.timestamp + MONTH;
        _funder = msg.sender;

        // create the vote tokens that will be used to vote on the proposal.
        INFTGemGovernor(_governor).createProposalVoteTokens(uint256(address(this)));

        // check for overpayment and if found then return remainder to user
        uint256 overpayAmount = msg.value.sub(PROPOSAL_COST);
        if (overpayAmount > 0) {
            (bool success, ) = payable(msg.sender).call{value: overpayAmount}("");
            require(success, "REFUND_FAILED");
        }
    }

    function execute() external override {
        // ensure we are funded and open and not executed
        require(_funded, "NOT_FUNDED");
        require(!_closed, "IS_CLOSED");
        require(!_executed, "IS_EXECUTED");
        require(_status() == ProposalStatus.PASSED, "IS_FAILED");

        // create the vote tokens that will be used to vote on the proposal.
        INFTGemGovernor(_governor).executeProposal(address(this));

        // this proposal is now executed
        _executed = true;

        // dewstroy the now-useless vote tokens used to vote for this proposal
        INFTGemGovernor(_governor).destroyProposalVoteTokens(uint256(address(this)));

        // refurn the filing fee to the funder of the proposal
        (bool success, ) = _funder.call{value: PROPOSAL_COST}("");
        require(success, "EXECUTE_FAILED");
    }

    function close() external override {
        // ensure we are funded and open and not executed
        require(_funded, "NOT_FUNDED");
        require(!_closed, "IS_CLOSED");
        require(!_executed, "IS_EXECUTED");
        require(block.timestamp > _expiration, "IS_ACTIVE");
        require(_status() == ProposalStatus.FAILED, "IS_PASSED");

        // this proposal is now closed - no action was taken
        _closed = true;

        // destroy the now-useless vote tokens used to vote for this proposal
        INFTGemGovernor(_governor).destroyProposalVoteTokens(uint256(address(this)));

        // send the proposal funder their filing fee back
        (bool success, ) = _funder.call{value: PROPOSAL_COST}("");
        require(success, "EXECUTE_FAILED");
    }
}


// File src/factories/ProposalFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;






contract ProposalFactory is Controllable, IProposalFactory {
    address private operator;

    mapping(uint256 => address) private _getProposal;
    address[] private _allProposals;

    constructor() {
        _addController(msg.sender);
    }

    /**
     * @dev get the proposal for this
     */
    function getProposal(uint256 _symbolHash) external view override returns (address proposal) {
        proposal = _getProposal[_symbolHash];
    }

    /**
     * @dev get the proposal for this
     */
    function allProposals(uint256 idx) external view override returns (address proposal) {
        proposal = _allProposals[idx];
    }

    /**
     * @dev number of quantized addresses
     */
    function allProposalsLength() external view override returns (uint256 proposal) {
        proposal = _allProposals.length;
    }

    /**
     * @dev deploy a new proposal using create2
     */
    function createProposal(
        address submitter,
        string memory title,
        address proposalData,
        IProposal.ProposalType proposalType
    ) external override onlyController returns (address payable proposal) {

        // make sure this proposal doesnt already exist
        bytes32 salt = keccak256(abi.encodePacked(submitter, title));
        require(_getProposal[uint256(salt)] == address(0), "PROPOSAL_EXISTS"); // single check is sufficient

        // create the quantized erc20 token using create2, which lets us determine the
        // quantized erc20 address of a token without interacting with the contract itself
        bytes memory bytecode = type(Proposal).creationCode;

        // use create2 to deploy the quantized erc20 contract
        proposal = payable(Create2.deploy(0, salt, bytecode));

        // initialize  the proposal with submitter, proposal type, and proposal data
        Proposal(proposal).initialize(submitter, title, proposalData, IProposal.ProposalType(proposalType));

        // add teh new proposal to our lists for management
        _getProposal[uint256(salt)] = proposal;
        _allProposals.push(proposal);

        // emit an event about the new proposal being created
        emit ProposalCreated(submitter, uint256(proposalType), proposal);
    }
}


// File src/fees/NFTGemFeeManager.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;


contract NFTGemFeeManager is INFTGemFeeManager {
    address private operator;

    uint256 private constant MINIMUM_LIQUIDITY = 100;
    uint256 private constant FEE_DIVISOR = 1000;

    mapping(address => uint256) private feeDivisors;
    uint256 private _defaultFeeDivisor;

    mapping(address => uint256) private _liquidity;
    uint256 private _defaultLiquidity;

    /**
     * @dev constructor
     */
    constructor() {
        _defaultFeeDivisor = FEE_DIVISOR;
        _defaultLiquidity = MINIMUM_LIQUIDITY;
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    receive() external payable {
        //
    }

    /**
     * @dev Set the address allowed to mint and burn
     */
    function setOperator(address _operator) external {
        require(operator == address(0), "IMMUTABLE");
        operator = _operator;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function liquidity(address token) external view override returns (uint256) {
        return _liquidity[token] != 0 ? _liquidity[token] : _defaultLiquidity;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultLiquidity() external view override returns (uint256 multiplier) {
        return _defaultLiquidity;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultLiquidity(uint256 _liquidityMult) external override returns (uint256 oldLiquidity) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_liquidityMult != 0, "INVALID");
        oldLiquidity = _defaultLiquidity;
        _defaultLiquidity = _liquidityMult;
        emit LiquidityChanged(operator, oldLiquidity, _defaultLiquidity);
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function feeDivisor(address token) external view override returns (uint256 divisor) {
        divisor = feeDivisors[token];
        divisor = divisor == 0 ? FEE_DIVISOR : divisor;
    }

    /**
     * @dev Get the fee divisor for the specified token
     */
    function defaultFeeDivisor() external view override returns (uint256 multiplier) {
        return _defaultFeeDivisor;
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setDefaultFeeDivisor(uint256 _feeDivisor) external override returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = _defaultFeeDivisor;
        _defaultFeeDivisor = _feeDivisor;
        emit DefaultFeeDivisorChanged(operator, oldDivisor, _defaultFeeDivisor);
    }

    /**
     * @dev Set the fee divisor for the specified token
     */
    function setFeeDivisor(address token, uint256 _feeDivisor) external override returns (uint256 oldDivisor) {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(_feeDivisor != 0, "DIVISIONBYZERO");
        oldDivisor = feeDivisors[token];
        feeDivisors[token] = _feeDivisor;
        emit FeeDivisorChanged(operator, token, oldDivisor, _feeDivisor);
    }

    /**
     * @dev get the ETH balance of this fee manager
     */
    function ethBalanceOf() external view override returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev get the token balance of this fee manager
     */
    function balanceOF(address token) external view override returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
     * @dev transfer ETH from this contract to the to given recipient
     */
    function transferEth(address payable recipient, uint256 amount) external override {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(address(this).balance >= amount, "INSUFFICIENT_BALANCE");
        recipient.transfer(amount);
    }

    /**
     * @dev transfer tokens from this contract to the to given recipient
     */
    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) external override {
        require(operator == msg.sender, "UNAUTHORIZED");
        require(IERC20(token).balanceOf(address(this)) >= amount, "INSUFFICIENT_BALANCE");
        IERC20(token).transfer(recipient, amount);
    }
}


// File src/governance/ChangeFeeProposalData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract ChangeFeeProposalData is IChangeFeeProposalData {
    address private token;
    address private pool;
    uint256 private feeDivisor;

    constructor(
        address _token,
        address _pool,
        uint256 _feeDivisor
    ) {
        token = _token;
        pool = _pool;
        feeDivisor = _feeDivisor;
    }

    function data()
        external
        view
        override
        returns (
            address,
            address,
            uint256
        )
    {
        return (token, pool, feeDivisor);
    }
}


// File src/governance/CreatePoolProposalData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract CreatePoolProposalData is ICreatePoolProposalData {
    
    string private symbol;
    string private name;
    
    uint256 private ethPrice;
    uint256 private minTime;
    uint256 private maxTime;
    uint256 private diffstep;
    uint256 private maxClaims;
    
    address private allowedToken;

    constructor(
        string memory _symbol,
        string memory _name,

        uint256 _ethPrice,
        uint256 _minTIme,
        uint256 _maxTime,
        uint256 _diffStep,
        uint256 _maxCLaim,
        
        address _allowedToken
    ) {
        symbol = _symbol;
        name = _name;
        ethPrice = _ethPrice;
        minTime = _minTIme;
        maxTime = _maxTime;
        diffstep = _diffStep;
        maxClaims = _maxCLaim;
        allowedToken = _allowedToken;
    }

    function data()
        external
        view
        override
        returns (
            string memory,
            string memory,

            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            
            address
        )
    {
        return (
            symbol, 
            name, 
            
            ethPrice, 
            minTime, 
            maxTime, 
            diffstep, 
            maxClaims, 
            
            allowedToken);

    }
}


// File src/governance/FundProjectProposalData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract FundProjectProposalData is IFundProjectProposalData {
    address private receiver;
    string private descriptionUrl;
    uint256 private ethAmount;

    constructor(
        address _receiver,
        string memory _descriptionUrl,
        uint256 _ethAmount
    ) {
        receiver = _receiver;
        descriptionUrl = _descriptionUrl;
        ethAmount = _ethAmount;
    }

    function data()
        external
        view
        override
        returns (
            address,
            string memory,
            uint256
        )
    {
        return (receiver, descriptionUrl, ethAmount);
    }
}


// File src/governance/UpdateAllowlistProposalData.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract UpdateAllowlistProposalData is IUpdateAllowlistProposalData {
    address private token;
    address private pool;
    bool private newStatus;

    constructor(
        address _token,
        address _pool,
        bool _newStatus
    ) {
        token = _token;
        pool = _pool;
        newStatus = _newStatus;
    }

    function data()
        external
        view
        override
        returns (
            address,
            address,
            bool
        )
    {
        return (token, pool, newStatus);
    }
}


// File src/governance/ProposalsLib.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;










library ProposalsLib {
    event GovernanceTokenIssued(address indexed receiver, uint256 amount);
    event FeeUpdated(address indexed proposal, address indexed token, uint256 newFee);
    event AllowList(address indexed proposal, address indexed pool, address indexed token, bool isBanned);
    event ProjectFunded(address indexed proposal, address indexed receiver, uint256 received);

    // create a proposal and associate it with passed-in proposal data
    function associateProposal(
        address governor,
        address multitoken,
        address proposalFactory,
        address submitter,
        IProposal.ProposalType propType,
        string memory title,
        address data
    ) internal returns (address p) {
        p = IProposalFactory(proposalFactory).createProposal(submitter, title, data, propType);
        IProposal(p).setMultiToken(multitoken);
        IProposal(p).setGovernor(governor);
        IControllable(multitoken).addController(p);
        IControllable(governor).addController(p);
    }

    // create a new pool proposal
    function createNewPoolProposal(
        string memory symbol,
        string memory name,

        uint256 ethPrice,
        uint256 minTime,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,

        address allowedToken
    ) public returns (address) {
        return
            address(
                new CreatePoolProposalData(
                    symbol,
                    name,

                    ethPrice,
                    minTime,
                    maxTime,
                    diffStep,
                    maxClaims,

                    allowedToken
                )
            );
    }

    // create a fee change proposal
    function createChangeFeeProposal(
        address token,
        address pool,
        uint256 feeDivisor
    ) public returns (address) {
        return address(
            new ChangeFeeProposalData(
                token,
                pool,
                feeDivisor));
    }

    // create a project funding proposal
    function createFundProjectProposal(
        address receiver,
        string memory descriptionUrl,
        uint256 ethAmount
    ) public returns (address) {
        return address(new FundProjectProposalData(
            receiver,
            descriptionUrl,
            ethAmount));
    }

    // create an allowlist modify proposal
    function createUpdateAllowlistProposal(
        address token,
        address pool,
        bool newStatus
    ) public returns (address) {
        return address(new UpdateAllowlistProposalData(token, pool, newStatus));
    }

    /**
     * @dev execute this proposal if it is in the right state. Anyone can execute a proposal
     */
    function executeProposal(
        address multitoken,
        address factory,
        address governor,
        address feeTracker,
        address swapHelper,
        address proposalAddress
    ) external {
        require(proposalAddress != address(0), "INVALID_PROPOSAL");
        require(IProposal(proposalAddress).status() == IProposal.ProposalStatus.PASSED, "PROPOSAL_NOT_PASSED");
        address prop = IProposal(proposalAddress).proposalData();
        require(prop != address(0), "INVALID_PROPOSAL_DATA");

        // craete a new NFT mining pool
        if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.CREATE_POOL) {
            address pool = GovernanceLib.execute(factory, proposalAddress);
            IControllable(multitoken).addController(pool);
            IControllable(governor).addController(pool);
            INFTGemPool(pool).setMultiToken(multitoken);
            INFTGemPool(pool).setSwapHelper(swapHelper);
            INFTGemPool(pool).setGovernor(address(this));
            INFTGemPool(pool).setFeeTracker(feeTracker);
            INFTGemPool(pool).mintGenesisGems(IProposal(proposalAddress).creator(), IProposal(proposalAddress).funder());
        }
        // fund a project
        else if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.FUND_PROJECT) {
            (address receiver, , uint256 amount) = IFundProjectProposalData(prop).data();
            INFTGemFeeManager(feeTracker).transferEth(payable(receiver), amount);
            emit ProjectFunded(address(proposalAddress), address(receiver), amount);
        }
        // change a fee
        else if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.CHANGE_FEE) {
            require(prop != address(0), "INVALID_PROPOSAL_DATA");
            address proposalData = IProposal(proposalAddress).proposalData();
            (address token, address pool, uint256 feeDiv) = IChangeFeeProposalData(proposalData).data();
            require(feeDiv != 0, "INVALID_FEE");
            if (token != address(0)) INFTGemFeeManager(feeTracker).setFeeDivisor(token, feeDiv);
            if (pool != address(0)) INFTGemFeeManager(feeTracker).setFeeDivisor(pool, feeDiv);
            if (token == address(0) && pool == address(0)) {
                INFTGemFeeManager(feeTracker).setDefaultFeeDivisor(feeDiv);
            }
        }
        // modify the allowlist
        else if (IProposal(proposalAddress).proposalType() == IProposal.ProposalType.UPDATE_ALLOWLIST) {
            address proposalData = IProposal(proposalAddress).proposalData();
            (address token, address pool, bool isAllowed) = IUpdateAllowlistProposalData(proposalData).data();
            require(token != address(0), "INVALID_TOKEN");
            if (isAllowed) {
                INFTGemPoolData(pool).addAllowedToken(token);
                emit AllowList(proposalAddress, pool, token, isAllowed);
            } else {
                INFTGemPoolData(pool).removeAllowedToken(token);
            }
        }
    }
}


// File hardhat/console.sol@v2.2.1

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}


// File src/governance/NFTGemGovernor.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;












contract NFTGemGovernor is Initializable, Controllable, INFTGemGovernor {
    using SafeMath for uint256;

    address private multitoken;
    address private factory;
    address private feeTracker;
    address private proposalFactory;
    address private swapHelper;

    uint256 private constant GOVERNANCE = 0;
    uint256 private constant FUEL = 1;
    uint256 private constant GOV_TOKEN_INITIAL = 500000;
    uint256 private constant GOV_TOKEN_MAX     = 1000000;

    bool private governanceIssued;

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
    ) external override initializer {
        multitoken = _multitoken;
        factory = _factory;
        feeTracker = _feeTracker;
        proposalFactory = _proposalFactory;
        swapHelper = _swapHelper;
    }

    /**
     * @dev create proposal vote tokens
     */
    function createProposalVoteTokens(uint256 proposalHash) external override onlyController {
        GovernanceLib.createProposalVoteTokens(multitoken, proposalHash);
    }

    /**
     * @dev destroy proposal vote tokens
     */
    function destroyProposalVoteTokens(uint256 proposalHash) external override onlyController {
        GovernanceLib.destroyProposalVoteTokens(multitoken, proposalHash);
    }

    /**
     * @dev execute proposal
     */
    function executeProposal(address propAddress) external override onlyController {
        ProposalsLib.executeProposal(multitoken, factory, address(this), feeTracker, swapHelper, propAddress);
    }

    /**
     * @dev issue initial governance tokens
     */
    function issueInitialGovernanceTokens(address receiver) external override returns (uint256) {
        require(!governanceIssued, "ALREADY_ISSUED");
        INFTGemMultiToken(multitoken).mint(receiver, GOVERNANCE, GOV_TOKEN_INITIAL);
        governanceIssued = true;
        emit GovernanceTokenIssued(receiver, GOV_TOKEN_INITIAL);
    }

    /**
     * @dev maybe issue a governance token to receiver
     */
    function maybeIssueGovernanceToken(address receiver) external override onlyController returns (uint256) {
        uint256 totalSupplyOf = INFTGemMultiToken(multitoken).totalBalances(GOVERNANCE);
        if (totalSupplyOf >= GOV_TOKEN_MAX) {
            return 0;
        }
        INFTGemMultiToken(multitoken).mint(receiver, GOVERNANCE, 1);
        emit GovernanceTokenIssued(receiver, 1);
    }

    /**
     * @dev shhh
     */
    function issueFuelToken(address receiver, uint256 amount) external override onlyController returns (uint256) {
        INFTGemMultiToken(multitoken).mint(receiver, FUEL, amount);
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
        IControllable(this).addController(pool);
        INFTGemPool(pool).setMultiToken(multitoken);
        INFTGemPool(pool).setSwapHelper(swapHelper);
        INFTGemPool(pool).setGovernor(address(this));
        INFTGemPool(pool).setFeeTracker(feeTracker);
        INFTGemPool(pool).mintGenesisGems(creator, funder);
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
        associatePool(IProposal(pool).creator(), IProposal(pool).funder(), pool);
    }

    /**
     * @dev create a proposal to create a new pool
     */
    function createNewPoolProposal(
        address submitter,
        string memory title,
        string memory symbol,
        string memory name,
        uint256 ethPrice,
        uint256 minTIme,
        uint256 maxTime,
        uint256 diffStep,
        uint256 maxClaims,
        address allowedToken
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createNewPoolProposal(
            symbol,
            name,
            ethPrice,
            minTIme,
            maxTime,
            diffStep,
            maxClaims,
            allowedToken
        );
        ProposalsLib.associateProposal(
            address(this),
            multitoken,
            proposalFactory,
            submitter,
            IProposal.ProposalType.CREATE_POOL,
            title,
            proposal
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
        proposal = ProposalsLib.createChangeFeeProposal(token, pool, feeDivisor);
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
     * @dev create a proposal to craete a project funding proposal
     */
    function createFundProjectProposal(
        address submitter,
        string memory title,
        address receiver,
        string memory descriptionUrl,
        uint256 ethAmount
    ) external override returns (address proposal) {
        proposal = ProposalsLib.createFundProjectProposal(receiver, descriptionUrl, ethAmount);
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
        proposal = ProposalsLib.createUpdateAllowlistProposal(token, pool, newStatus);
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


// File src/interfaces/IERC1155MetadataURI.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}


// File @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol@v1.1.0-beta.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol@v1.1.0-beta.0

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol@v1.0.1

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File src/swap/funiswap/FuniswapLib.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev Uniswap helpers
 */
library FuniswapLib {

    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function ethQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address _factory = uniswapRouter.factory();
        address _WETH = uniswapRouter.WETH();
        address _pair = IUniswapV2Factory(_factory).getPair(token, _WETH);
        (tokenReserve, ethReserve, ) = IUniswapV2Pair(_pair).getReserves();
        ethereum = quote(tokenAmount, tokenReserve, ethReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function WETH() external pure returns (address weth) {
        weth = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).WETH();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address _factory = uniswapRouter.factory();
        address _WETH = uniswapRouter.WETH();
        address _pair = IUniswapV2Factory(_factory).getPair(token, _WETH);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IUniswapV2Factory(_factory).getPair(
                tokenA,
                tokenB
            );
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IUniswapV2Pair(pair).getReserves();
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        _factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForETHToToken(address token) external pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        return path;
    }

    /**
     * @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    /**
     * @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}


// File src/swap/funiswap/FuniswapQueryHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


/**
 * @dev Funiswap helpers
 */
contract FuniswapQueryHelper is ISwapQueryHelper {

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return FuniswapLib.ethQuote(token, tokenAmount);
    }

    /**
     * @dev does a Funiswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = FuniswapLib.factory();
    }

    /**
     * @dev does a Funiswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = FuniswapLib.WETH();
    }


    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = FuniswapLib.factory();
        pair = FuniswapLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = FuniswapLib.getReserves(pair);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) external pure override returns (address pair) {
        address _factory = FuniswapLib.factory();
        pair = FuniswapLib.pairFor(_factory, tokenA, tokenB);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return FuniswapLib.hasPool(token);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return FuniswapLib.getPathForETHToToken(token);
    }

}


// File src/swap/mock/MockQueryHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


/**
 * @dev Mock helper for local network
 */
contract MockQueryHelper is ISwapQueryHelper {
    using SafeMath for uint256;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address, uint256 tokenAmount)
        external
        pure
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return ( tokenAmount.div(10), tokenAmount.mul(200), tokenAmount.mul(20));
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = address(0);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = address(99);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address, address) external pure override returns (address pair) {
        pair = address(0);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address
    ) external pure override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = (0, 0);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address,
        address
    ) external pure override returns (address pair) {
        pair = address(0);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address) external pure override returns (bool) {
        return true;
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address) external pure override returns (address[] memory) {
        address[] memory _mock;
        return _mock;
    }

}


// File pancakeswap-peripheral/contracts/interfaces/IPancakeRouter01.sol@v1.1.0-beta.0

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}


// File pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol@v1.1.0-beta.0

pragma solidity >=0.6.2;
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakeFactory.sol@v0.1.0

pragma solidity >=0.5.0;

interface IPancakeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @pancakeswap-libs/pancake-swap-core/contracts/interfaces/IPancakePair.sol@v0.1.0

pragma solidity >=0.5.0;

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File src/swap/pancakeswap/PancakeSwapLib.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev pancake helpers
 */
library PancakeSwapLib {

    address public constant PANCAKE_ROUTER_ADDRESS = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 coin,
            uint256 tokenReserve,
            uint256 coinReserve
        )
    {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS );
        address _factory = pancakeRouter.factory();
        address _COIN = pancakeRouter.WETH();
        address _pair = IPancakeFactory(_factory).getPair(token, _COIN);
        (tokenReserve, coinReserve, ) = IPancakePair(_pair).getReserves();
        coin = quote(tokenAmount, tokenReserve, coinReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS ).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure returns (address wavax) {
        wavax = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS ).WETH();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS );
        address _factory = pancakeRouter.factory();
        address _WAVAX = pancakeRouter.WETH();
        address _pair = IPancakeFactory(_factory).getPair(token, _WAVAX);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs wavax
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IPancakeFactory(_factory).getPair(
                tokenA,
                tokenB
            );
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IPancakePair(pair).getReserves();
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        _factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"d0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for coin to the given token
     */
    function getPathForCoinToToken(address token) external pure returns (address[] memory) {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(PANCAKE_ROUTER_ADDRESS );
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = pancakeRouter.WETH();
        return path;
    }

    /**
     * @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    /**
     * @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}


// File src/swap/pancakeswap/PancakeSwapQueryHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


/**
 * @dev Uniswap helpers
 */
contract PancakeSwapQueryHelper is ISwapQueryHelper {

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return PancakeSwapLib.coinQuote(token, tokenAmount);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = PancakeSwapLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = PancakeSwapLib.COIN();
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return PancakeSwapLib.hasPool(token);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = PancakeSwapLib.factory();
        pair = PancakeSwapLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = PancakeSwapLib.getReserves(pair);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) external pure override returns (address pair) {
        address _factory = PancakeSwapLib.factory();
        pair = PancakeSwapLib.pairFor(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return PancakeSwapLib.getPathForCoinToToken(token);
    }

}


// File @pangolindex/exchange-contracts/contracts/pangolin-periphery/interfaces/IPangolinRouter.sol@v1.0.1

pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


// File @pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinFactory.sol@v1.0.1

pragma solidity >=0.5.0;

interface IPangolinFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// File @pangolindex/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinPair.sol@v1.0.1

pragma solidity >=0.5.0;

interface IPangolinPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File src/swap/pangolin/PangolinLib.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev Uniswap helpers
 */
library PangolinLib {

    address public constant PANGOLIN_ROUTER_ADDRESS = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
    address public constant FUJI_PANGOLIN_ROUTER_ADDRESS = 0xE4A575550C2b460d2307b82dCd7aFe84AD1484dd;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function avaxQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 avalanche,
            uint256 tokenReserve,
            uint256 avaxReserve
        )
    {
        IPangolinRouter uniswapRouter = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS );
        address _factory = uniswapRouter.factory();
        address _WAVAX = uniswapRouter.WAVAX();
        address _pair = IPangolinFactory(_factory).getPair(token, _WAVAX);
        (tokenReserve, avaxReserve, ) = IPangolinPair(_pair).getReserves();
        avalanche = quote(tokenAmount, tokenReserve, avaxReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS ).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function WAVAX() external pure returns (address wavax) {
        wavax = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS ).WAVAX();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IPangolinRouter uniswapRouter = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS );
        address _factory = uniswapRouter.factory();
        address _WAVAX = uniswapRouter.WAVAX();
        address _pair = IPangolinFactory(_factory).getPair(token, _WAVAX);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs wavax
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IPangolinFactory(_factory).getPair(
                tokenA,
                tokenB
            );
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IPangolinPair(pair).getReserves();
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        _factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"40231f6b438bce0797c9ada29b718a87ea0a5cea3fe9a771abdd76bd41a3e545" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for avalanche to the given token
     */
    function getPathForAVAXoToken(address token) external pure returns (address[] memory) {
        IPangolinRouter uniswapRouter = IPangolinRouter(PANGOLIN_ROUTER_ADDRESS );
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WAVAX();
        return path;
    }

    /**
     * @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    /**
     * @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}


// File src/swap/pangolin/PangolinQueryHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev Uniswap helpers
 */
contract PangolinQueryHelper is ISwapQueryHelper, Controllable {

    address private _routerAddress;

    address public constant PANGOLIN_ROUTER_ADDRESS = 0xefa94DE7a4656D787667C749f7E1223D71E9FD88;
    address public constant FUJI_PANGOLIN_ROUTER_ADDRESS = 0xE4A575550C2b460d2307b82dCd7aFe84AD1484dd;

    constructor() {
        _routerAddress = PANGOLIN_ROUTER_ADDRESS;
    }

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return PangolinLib.avaxQuote(token, tokenAmount);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = PangolinLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = PangolinLib.WAVAX();
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return PangolinLib.hasPool(token);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = PangolinLib.factory();
        pair = PangolinLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = PangolinLib.getReserves(pair);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) external pure override returns (address pair) {
        address _factory = PangolinLib.factory();
        pair = PangolinLib.pairFor(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return PangolinLib.getPathForAVAXoToken(token);
    }

}


// File src/swap/uniswap/UniswapLib.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;



/**
 * @dev Uniswap helpers
 */
library UniswapLib {

    address public constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function ethQuote(address token, uint256 tokenAmount)
        external
        view
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address _factory = uniswapRouter.factory();
        address _WETH = uniswapRouter.WETH();
        address _pair = IUniswapV2Factory(_factory).getPair(token, _WETH);
        (tokenReserve, ethReserve, ) = IUniswapV2Pair(_pair).getReserves();
        ethereum = quote(tokenAmount, tokenReserve, ethReserve);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure returns (address fac) {
        fac = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function WETH() external pure returns (address weth) {
        weth = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS).WETH();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function hasPool(address token) external view returns (bool) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address _factory = uniswapRouter.factory();
        address _WETH = uniswapRouter.WETH();
        address _pair = IUniswapV2Factory(_factory).getPair(token, _WETH);
        return _pair != address(0);
    }

    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address _factory, address tokenA, address tokenB) external view returns (address pair) {
        require(_factory != address(0), "INVALID_TOKENS");
        require(tokenA != address(0) && tokenB != address(0), "INVALID_TOKENS");
        pair =
            IUniswapV2Factory(_factory).getPair(
                tokenA,
                tokenB
            );
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB, ) = IUniswapV2Pair(pair).getReserves();
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address _factory,
        address tokenA,
        address tokenB
    ) external pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        _factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f" // init code hash
                    )
                )
            )
        );
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForETHToToken(address token) external pure returns (address[] memory) {
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        address[] memory path = new address[](2);
        path[0] = token;
        path[1] = uniswapRouter.WETH();
        return path;
    }

    /**
     * @dev given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
     */
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "Price: Price");
        require(reserveA > 0 && reserveB > 0, "Price: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * (reserveB)) / reserveA;
    }

    /**
     * @dev returns sorted token addresses, used to handle return values from pairs sorted in this order
     */
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "Price: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "Price: ZERO_ADDRESS");
    }
}


// File src/swap/uniswap/UniswapQueryHelper.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


/**
 * @dev Uniswap helpers
 */
contract UniswapQueryHelper is ISwapQueryHelper {

    /**
     * @dev Get a quote in Ethereum for the given ERC20 token / token amount
     */
    function coinQuote(address token, uint256 tokenAmount)
        external
        view
        override
        returns (
            uint256 ethereum,
            uint256 tokenReserve,
            uint256 ethReserve
        )
    {
       return UniswapLib.ethQuote(token, tokenAmount);
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function factory() external pure override returns (address fac) {
        fac = UniswapLib.factory();
    }

    /**
     * @dev does a Uniswap pool exist for this token?
     */
    function COIN() external pure override returns (address weth) {
        weth = UniswapLib.WETH();
    }


    /**
     * @dev looks for a pool vs weth
     */
    function getPair(address tokenA, address tokenB) external view override returns (address pair) {
        address _factory = UniswapLib.factory();
        pair = UniswapLib.getPair(_factory, tokenA, tokenB);
    }

    /**
     * @dev Get the pair reserves given two erc20 tokens
     */
    function getReserves(
        address pair
    ) external view override returns (uint256 reserveA, uint256 reserveB) {
        (reserveA, reserveB) = UniswapLib.getReserves(pair);
    }

    /**
     * @dev calculate pair address
     */
    function pairFor(
        address tokenA,
        address tokenB
    ) external pure override returns (address pair) {
        address _factory = UniswapLib.factory();
        pair = UniswapLib.pairFor(_factory, tokenA, tokenB);
    }

    /**
     * @dev does token have a pool
     */
    function hasPool(address token) external view override returns (bool) {
        return UniswapLib.hasPool(token);
    }

    /**
     * @dev Get a path for ethereum to the given token
     */
    function getPathForCoinToToken(address token) external pure override returns (address[] memory) {
        return UniswapLib.getPathForETHToToken(token);
    }

}


// File src/tokens/ERC1155.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;







/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) internal _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /*
     *     bytes4(keccak256('balanceOf(address,uint256)')) == 0x00fdd58e
     *     bytes4(keccak256('balanceOfBatch(address[],uint256[])')) == 0x4e1273f4
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,uint256,bytes)')) == 0xf242432a
     *     bytes4(keccak256('safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)')) == 0x2eb2c2d6
     *
     *     => 0x00fdd58e ^ 0x4e1273f4 ^ 0xa22cb465 ^
     *        0xe985e9c5 ^ 0xf242432a ^ 0x2eb2c2d6 == 0xd9b67a26
     */
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /*
     *     bytes4(keccak256('uri(uint256)')) == 0x0e89341c
     */
    bytes4 private constant _INTERFACE_ID_ERC1155_METADATA_URI = 0x0e89341c;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);

        // register the supported interfaces to conform to ERC1155 via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155);

        // register the supported interfaces to conform to ERC1155MetadataURI via ERC165
        _registerInterface(_INTERFACE_ID_ERC1155_METADATA_URI);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
            _balances[id][to] = _balances[id][to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(amount, "ERC1155: burn amount exceeds balance");

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][account] = _balances[ids[i]][account].sub(
                amounts[i],
                "ERC1155: burn amount exceeds balance"
            );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) internal pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}


// File src/utils/Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


// File src/tokens/ERC1155Pausable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;


/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155Pausable is ERC1155, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
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

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}


// File src/tokens/ERC20WrappedERC1155.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;





contract ERC20WrappedERC1155 is ERC20, ERC1155Holder {
    using SafeMath for uint256;

    address private token;
    uint256 private index;
    uint256 private rate;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        address erc1155Token,
        uint256 tokenIndex,
        uint256 exchangeRate
    ) ERC20(name, symbol) {
        token = erc1155Token;
        index = tokenIndex;
        rate = exchangeRate;
        _setupDecimals(decimals);
    }

    function wrap(uint256 quantity) external {

        require(quantity != 0, "ZERO_QUANTITY");
        require(IERC1155(token).balanceOf(msg.sender, index) >= quantity, "INSUFFICIENT_ERC1155_BALANCE");

        IERC1155(token).safeTransferFrom(msg.sender, address(this), index, quantity, "");
        _mint(msg.sender, quantity.mul(rate));

    }

    function unwrap(uint256 quantity) external {

        require(quantity != 0, "ZERO_QUANTITY");
        require(balanceOf(msg.sender) >= quantity.mul(rate), "INSUFFICIENT_ERC20_BALANCE");

        _burn(msg.sender, quantity.mul(rate));
        IERC1155(token).safeTransferFrom(address(this), msg.sender, index, quantity, "");

    }
}


// File src/libs/Strings.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

library Strings {
    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d,
        string memory _e
    ) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (uint256 i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (uint256 i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (uint256 i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (uint256 i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c,
        string memory _d
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string memory _a,
        string memory _b,
        string memory _c
    ) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + (_i % 10)));
            _i /= 10;
        }
        return string(bstr);
    }
}


// File src/tokens/NFTGemMultiToken.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;






contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract NFTGemMultiToken is ERC1155Pausable, ERC1155Holder, INFTGemMultiToken, Controllable {
    using SafeMath for uint256;
    using Strings for string;

    // allows opensea to
    address private constant OPENSEA_REGISTRY_ADDRESS = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    address[] private proxyRegistries;
    address private registryManager;

    mapping(uint256 => uint256) private _totalBalances;
    mapping(address => mapping(uint256 => uint256)) private _tokenLocks;

    mapping(address => uint256[]) private _heldTokens;
    mapping(uint256 => address[]) private _tokenHolders;

    /**
     * @dev Contract initializer.
     */
    constructor() ERC1155("https://metadata.bitgem.co/") {
        _addController(msg.sender);
        registryManager = msg.sender;
        proxyRegistries.push(OPENSEA_REGISTRY_ADDRESS);
    }

    function lock(uint256 token, uint256 timestamp) external override {
        require(_tokenLocks[_msgSender()][token] < timestamp, "ALREADY_LOCKED");
        _tokenLocks[_msgSender()][timestamp] = timestamp;
    }

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
     * @dev Returns the total balance minted of this type
     */
    function allHeldTokens(address holder, uint256 _idx) external view override returns (uint256) {
        return _heldTokens[holder][_idx];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allHeldTokensLength(address holder) external view override returns (uint256) {
        return _heldTokens[holder].length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allTokenHolders(uint256 _token, uint256 _idx) external view override returns (address) {
        return _tokenHolders[_token][_idx];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allTokenHoldersLength(uint256 _token) external view override returns (uint256) {
        return _tokenHolders[_token].length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function totalBalances(uint256 _id) external view override returns (uint256) {
        return _totalBalances[_id];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allProxyRegistries(uint256 _idx) external view override returns (address) {
        return proxyRegistries[_idx];
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function getRegistryManager() external view override returns (address) {
        return registryManager;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function setRegistryManager(address newManager) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        require(newManager != address(0), "UNAUTHORIZED");
        registryManager = newManager;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function allProxyRegistriesLength() external view override returns (uint256) {
        return proxyRegistries.length;
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function addProxyRegistry(address registry) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        proxyRegistries.push(registry);
    }

    /**
     * @dev Returns the total balance minted of this type
     */
    function removeProxyRegistryAt(uint256 index) external override {
        require(msg.sender == registryManager, "UNAUTHORIZED");
        require(index < proxyRegistries.length, "INVALID_INDEX");
        proxyRegistries[index] = proxyRegistries[proxyRegistries.length - 1];
        delete proxyRegistries[proxyRegistries.length - 1];
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-free listings.
     */
    function isApprovedForAll(address _owner, address _operator) public view override returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        for(uint256 i = 0; i < proxyRegistries.length; i++) {
            ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistries[i]);
            if (address(proxyRegistry.proxies(_owner)) == _operator) {
                return true;
            }
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
     * @dev mint some amount of tokens. Only callable by token owner
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
     * @dev intercepting token transfers to manage a list of zero-token holders
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
            if (from != address(0) && balanceOf(from, ids[i]) - amounts[i] == 0) {
                // remove from heldTokens
                for (uint256 j = 0; j < _heldTokens[from].length; j++) {
                    if (_heldTokens[from][j] == ids[i]) {
                        _heldTokens[from][j] = _heldTokens[from][_heldTokens[from].length - 1];
                        delete _heldTokens[from][_heldTokens[from].length - 1];
                    }
                }
                // remove from tokenHolders
                for (uint256 j = 0; j < _tokenHolders[ids[i]].length; j++) {
                    if (_tokenHolders[ids[i]][j] == from) {
                        _tokenHolders[ids[i]][j] = _tokenHolders[ids[i]][_tokenHolders[ids[i]].length - 1];
                        delete _tokenHolders[ids[i]][_tokenHolders[ids[i]].length - 1];
                    }
                }
            }

            // if this is not a burn and receiver does not yet own token then
            // add that account to the token for that id
            if (to != address(0) && balanceOf(to, ids[i]) == 0) {
                _heldTokens[to].push(ids[i]);
                _tokenHolders[ids[i]].push(to);
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


// File src/tokens/TestToken.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract TestToken is ERC20 {
    constructor(string memory symbol, string memory name) ERC20(symbol, name) {
        _mint(msg.sender, 1000000 ether);
    }
}


// File src/interfaces/IInitializable.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

interface IControllable {
    function initialize(uint256) external;

    function initialize2(uint256, uint256) external;
}
