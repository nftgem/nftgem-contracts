
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

describe('NFTGem Core', async () => {
  before(async () => {
    [sender] = await ethers.getSigners();
    senderAddress = sender.address;
  });

  it('can deploy bitgems successfully', async () => {
    deployedContracts = await func(hre);
  });

  it('can access bitgems markets using its symbol hash and offset index', async () => {
    const marketsCount = await deployedContracts.NFTGemPoolFactory.allNFTGemPoolsLength();
    assert.equal(marketsCount.toNumber(), 9); // 8 plue the one created in the previous tests

    const marketHash = keccak256(
      ['bytes'],
      [
        pack(
          ['string'],
          ['RUBY']
        ),
      ]
    );

    const marketAddress1 = await deployedContracts.NFTGemPoolFactory.allNFTGemPools(
      0
    );
    const marketAddress2 = await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
      marketHash
    );
    assert.equal(marketAddress1, marketAddress2);
  });

  it('can read data from market correctly', async () => {
    console.log(`${senderAddress} : ${formatEther((await sender.getBalance()).toString())}`);
    const marketHash = keccak256(
      ['bytes'],
      [pack(['string'], ['RUBY'])]
    );
    const marketAddress2 = await deployedContracts.NFTGemPoolFactory.getNFTGemPool(marketHash);
    rubyMarket = ((await getContractAt(
      'NFTGemPool',
      marketAddress2,
      sender
    )) as unknown) as NFTGemPool;

    const ds = 86400;
    const ms = ds * 30;
    assert.equal(await rubyMarket.name(), 'Ruby');
    assert.equal(await rubyMarket.symbol(), 'RUBY');
    assert.equal((await rubyMarket.minTime()).toNumber(), ds);
    assert.equal((await rubyMarket.maxTime()).toNumber(), ms);
    assert.equal(
      parseFloat((await rubyMarket.ethPrice()).toString()) >= 0.01,
      true
    );
    assert.equal((await rubyMarket.difficultyStep()).toNumber(), 32);
    assert.equal((await rubyMarket.mintedCount()).toNumber(), 2);
  });

  it('can read data from multitoken correctly', async () => {
    console.log(`${senderAddress} : ${formatEther((await sender.getBalance()).toString())}`);

    const allTokensBalance = await deployedContracts.NFTGemMultiToken.allHeldTokensLength(
      senderAddress
    );
    assert.equal(allTokensBalance.toNumber() >= 16, true);
    for (let i = 0; i < allTokensBalance.toNumber(); i++) {
      const thisToken = await deployedContracts.NFTGemMultiToken.allHeldTokens(
        senderAddress,
        i
      );
      if (thisToken.eq(0)||thisToken.eq(1)) continue;
      const tokenBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
        senderAddress,
        thisToken
      );
      console.log(thisToken.toHexString(), tokenBalance.toNumber());
      assert.equal(tokenBalance.toNumber(), 1);
    }
    const govBalance = await deployedContracts.NFTGemMultiToken.balanceOf(
      senderAddress,
      0
    );
    assert.equal(govBalance.toNumber() >= 500000, true);
  });

  it('cannot purchase a claim below minimmum price', async () => {
    console.log(`${senderAddress} : ${formatEther((await sender.getBalance()).toString())}`);

    let hasError = false;
    const maxTime = await (await rubyMarket.maxTime()).mul(2);
    try {
      await rubyMarket.createClaim(maxTime);
    } catch (e) {
      hasError = true;
    }
    assert.equal(hasError, true);
  });

  it('cannot purchase a claim above maximum price', async () => {
    console.log(`${senderAddress} : ${formatEther((await sender.getBalance()).toString())}`);

    let hasError = false;
    const minTime = await (await rubyMarket.minTime()).div(2);
    try {
      await rubyMarket.createClaim(minTime);
    } catch (e) {
      hasError = true;
    }
    assert.equal(hasError, true);
  });

  it('can purchase max price claim correctly', async () => {
    console.log(`${senderAddress} : ${formatEther((await sender.getBalance()).toString())}`);

    const claimCost = await rubyMarket.ethPrice();
    const minTime = await rubyMarket.minTime();
    console.log(minTime.toString(), formatEther(claimCost.toString()))
    await rubyMarket.createClaim(minTime, {value: claimCost.toHexString()});
  });

  it('can purchase min price claim correctly', async () => {
    console.log(`${senderAddress} : ${formatEther((await sender.getBalance()).toString())}`);
    const claimCost = await rubyMarket.ethPrice();
    const minTime = await rubyMarket.minTime();
    const maxTime = await rubyMarket.maxTime();
    const minCost = claimCost.div(maxTime).mul(minTime);
    await rubyMarket.createClaim(maxTime, {value: minCost.toHexString()});
    const thisToken = await deployedContracts.NFTGemMultiToken.allHeldTokens(senderAddress, 18);
    const balanceOf = await deployedContracts.NFTGemMultiToken.balanceOf(senderAddress, thisToken);
    assert.equal(balanceOf.toNumber(), 1);
  });
});
