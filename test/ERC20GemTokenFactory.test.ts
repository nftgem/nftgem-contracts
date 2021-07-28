import {expect} from './chai-setup';
import {ethers} from 'hardhat';
import {pack, keccak256} from '@ethersproject/solidity';
import {
  setupERC20GemToken,
  createERC20Token,
} from './fixtures/ERC20GemToken.fixture';

const {utils} = ethers;
const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';
const data = {
  poolData: {
    symbol: 'RUBY',
    name: 'Ruby',
    ethPrice: utils.parseEther('1'),
    minTime: 86400,
    maxTime: 864000,
    diffStep: 1000,
    maxClaims: 0,
    allowedToken: ZERO_ADDRESS,
  },
  tokenData: {
    symbol: 'WRUBY',
    name: 'Wrapped Ruby',
    decimals: 8,
  },
};

describe('ERC20GemTokenFactory contract', function () {
  it('Should revert if erc20 token already exists', async function () {
    const {
      ERC20GemTokenFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
      poolAddress,
    } = await createERC20Token(data);
    await expect(
      ERC20GemTokenFactory.createItem(
        data.tokenData.symbol,
        data.tokenData.name,
        poolAddress,
        NFTGemMultiToken.address,
        data.tokenData.decimals,
        NFTGemFeeManager.address
      )
    ).to.be.revertedWith('GEMTOKEN_EXISTS');
  });
  it('Should revert if wrong pool address is passed', async function () {
    const {
      ERC20GemTokenFactory,
      NFTGemMultiToken,
      NFTGemFeeManager,
    } = await setupERC20GemToken();
    await expect(
      ERC20GemTokenFactory.createItem(
        data.tokenData.symbol,
        data.tokenData.name,
        ZERO_ADDRESS,
        NFTGemMultiToken.address,
        data.tokenData.decimals,
        NFTGemFeeManager.address
      )
    ).to.be.revertedWith('INVALID_POOL');
  });
  it('Should create erc20 token', async function () {
    const {ERC20GemTokenFactory} = await createERC20Token(data);
    const itemsLength = (
      await ERC20GemTokenFactory.allItemsLength()
    ).toNumber();
    expect(itemsLength).to.equal(1);
    const salt = keccak256(
      ['bytes'],
      [pack(['string'], [data.tokenData.symbol])]
    );
    const tokenAddress = await ERC20GemTokenFactory.getItem(salt);
    expect(await ERC20GemTokenFactory.allItems(itemsLength - 1)).to.equal(
      tokenAddress
    );
  });
  it('should return the length of all tokens', async function () {
    const {ERC20GemTokenFactory} = await createERC20Token(data);
    const itemsLength = (
      await ERC20GemTokenFactory.allItemsLength()
    ).toNumber();
    expect(itemsLength).to.equal(1);
  });
});
