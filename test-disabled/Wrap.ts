import {assert} from '../test/chai-setup';
import hre from 'hardhat';

import {NFTGemPoolFactory} from '../types/NFTGemPoolFactory';
import {NFTGemPool} from '../types/NFTGemPool';
import {pack, keccak256} from '@ethersproject/solidity';
import func from '../deploy/deploy';
import { formatEther, parseEther } from 'ethers/lib/utils';

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

const {ethers} = hre;
const {getContractAt} = ethers;

let sender: any,
  senderAddress: any,
  rubyMarket: NFTGemPool,
  deployedContracts: any;

describe('Wrap', async () => {
  before(async () => {
    [sender] = await ethers.getSigners();
    senderAddress = sender.address;
  });

  it('can deploy bitgems successfully', async () => {
    deployedContracts = await func(hre);
  });

});
