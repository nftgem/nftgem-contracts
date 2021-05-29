// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.7.0;

import "../exchange/Unigem1155Exchange.sol";
import "../interfaces/IUnigem1155Factory.sol";

contract Unigem1155Factory is IUnigem1155Factory {

  /***********************************|
  |       Events And Variables        |
  |__________________________________*/

  // tokensToExchange[erc1155_token_address][currency_address][currency_token_id]
  mapping(address => mapping(address => mapping(uint256 => address))) public override tokensToExchange;

  /***********************************|
  |            Constructor            |
  |__________________________________*/

  /**
   * @notice Creates a Unigem1155 Exchange for given token contract
   * @param _token      The address of the ERC-1155 token contract
   * @param _currency   The address of the currency token contract
   * @param _currencyID The id of the currency token
   */
  function createExchange(address _token, address _currency, uint256 _currencyID) public override {
    require(tokensToExchange[_token][_currency][_currencyID] == address(0x0), "UnigemFactory#createExchange: EXCHANGE_ALREADY_CREATED");

    // Create new exchange contract
    Unigem1155Exchange exchange = new Unigem1155Exchange(_token, _currency, _currencyID);

    // Store exchange and token addresses
    tokensToExchange[_token][_currency][_currencyID] = address(exchange);

    // Emit event
    emit NewExchange(_token, _currency, _currencyID, address(exchange));
  }

}
