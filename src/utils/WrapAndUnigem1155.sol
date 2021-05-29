// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

import "../interfaces/IUnigem1155Exchange.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IERC1155.sol";
import "../interfaces/IERC1155TokenReceiver.sol";
import "../interfaces/IERC20Wrapper.sol";

/**
 * @notice Will allow users to wrap their  ERC-20 into ERC-1155 tokens
 *         and pass their order to unigem. All funds will be returned
 *         to original owner and this contact should never hold any funds
 *         outside of a given wrap transaction.
 * @dev Hardcoding addresses for simplicity, easy to generalize if arguments
 *      are passed in functions, but adds a bit of complexity.
 */
contract WrapAndUnigem1155 {

  IERC20Wrapper immutable public tokenWrapper; // ERC-20 to ERC-1155 token wrapper contract
  address immutable public exchange;           // Unigem exchange to use
  address immutable public erc20;              // ERC-20 used in unigem exchange
  address immutable public erc1155;            // ERC-1155 used in unigem exchange

  uint256 immutable internal wrappedTokenID; // ID of the wrapped token
  bool internal isInUnigem;               // Whether unigem is being called

  /**
   * @notice Registers contract addresses
   */
  constructor(
    address payable _tokenWrapper,
    address _exchange,
    address _erc20,
    address _erc1155
  ) {
    require(
      _tokenWrapper != address(0x0) &&
      _exchange != address(0x0) &&
      _erc20 != address(0x0) &&
      _erc1155 != address(0x0),
      "INVALID CONSTRUCTOR ARGUMENT"
    );

    tokenWrapper = IERC20Wrapper(_tokenWrapper);
    exchange = _exchange;
    erc20 = _erc20;
    erc1155 = _erc1155;

    // Approve wrapper contract for ERC-20
    // NOTE: This could potentially fail in some extreme usage as it's only
    // set once, but can easily redeploy this contract if that's the case.
    IERC20(_erc20).approve(_tokenWrapper, 2**256-1);

    // Store wrapped token ID
    wrappedTokenID = IERC20Wrapper(_tokenWrapper).getTokenID(_erc20);
  }

  /**
   * @notice Wrap ERC-20 to ERC-1155 and swap them
   * @dev User must approve this contract for ERC-20 first
   * @param _maxAmount       Maximum amount of ERC-20 user wants to spend
   * @param _recipient       Address where to send tokens
   * @param _unigemOrder  Encoded Unigem order passed in data field of safeTransferFrom()
   */
  function wrapAndSwap(
    uint256 _maxAmount,
    address _recipient,
    bytes calldata _unigemOrder
  ) external
  {
    // Decode unigem order
    IUnigem1155Exchange.BuyTokensObj memory obj;
    (, obj) = abi.decode(_unigemOrder, (bytes4, IUnigem1155Exchange.BuyTokensObj));

    // Force the recipient to not be set, otherwise wrapped token refunded will be
    // sent to the user and we won't be able to unwrap it.
    require(
      obj.recipient == address(0x0) || obj.recipient == address(this),
      "WrapAndUnigem#wrapAndSwap: ORDER RECIPIENT MUST BE THIS CONTRACT"
    );

    // Pull ERC-20 amount specified in order
    IERC20(erc20).transferFrom(msg.sender, address(this), _maxAmount);

    // Wrap ERC-20s
    tokenWrapper.deposit(erc20, address(this), _maxAmount);

    // Swap on Unigem
    isInUnigem = true;
    tokenWrapper.safeTransferFrom(address(this), exchange, wrappedTokenID, _maxAmount, _unigemOrder);
    isInUnigem = false;

    // Unwrap ERC-20 and send to receiver, if any received
    uint256 wrapped_token_amount = tokenWrapper.balanceOf(address(this), wrappedTokenID);
    if (wrapped_token_amount > 0) {
      tokenWrapper.withdraw(erc20, payable(_recipient), wrapped_token_amount);
    }

    // Transfer tokens purchased
    IERC1155(erc1155).safeBatchTransferFrom(address(this), _recipient, obj.tokensBoughtIDs, obj.tokensBoughtAmounts, "");
  }

  /**
   * @notice Accepts only tokenWrapper tokens
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155Received(address, address, uint256, uint256, bytes calldata)
    external view returns(bytes4)
  {
    if (msg.sender != address(tokenWrapper)) {
      revert("WrapAndUnigem#onERC1155Received: INVALID_ERC1155_RECEIVED");
    }
    return IERC1155TokenReceiver.onERC1155Received.selector;
  }

  /**
   * @notice If receives tracked ERC-1155, it will send a sell order to unigem and unwrap received
   *         wrapped token. The unwrapped tokens will be sent to the sender.
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address,
    address _from,
    uint256[] calldata _ids,
    uint256[] calldata _amounts,
    bytes calldata _unigemOrder
  )
    external returns(bytes4)
  {
    // If coming from unigem or wrapped token, ignore
    if (isInUnigem || msg.sender == address(tokenWrapper)){
      return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
    } else if (msg.sender != erc1155) {
      revert("WrapAndUnigem#onERC1155BatchReceived: INVALID_ERC1155_RECEIVED");
    }

    // Decode transfer data
    IUnigem1155Exchange.SellTokensObj memory obj;
    (,obj) = abi.decode(_unigemOrder, (bytes4, IUnigem1155Exchange.SellTokensObj));

    require(
      obj.recipient == address(0x0) || obj.recipient == address(this),
      "WrapAndUnigem#onERC1155BatchReceived: RCPT MUST BE THIS CONTRACT"
    );

    // Swap on Unigem
    isInUnigem = true;
    IERC1155(msg.sender).safeBatchTransferFrom(address(this), exchange, _ids, _amounts, _unigemOrder);
    isInUnigem = false;

    // Send to recipient the unwrapped ERC-20, if any
    uint256 wrappedTokenAmount = tokenWrapper.balanceOf(address(this), wrappedTokenID);
    if (wrappedTokenAmount > 0) {
      // Doing it in 2 calls so tx history is more consistent
      tokenWrapper.withdraw(erc20, payable(address(this)), wrappedTokenAmount);
      IERC20(erc20).transfer(_from, wrappedTokenAmount);
    }

    return IERC1155TokenReceiver.onERC1155BatchReceived.selector;
  }
}
