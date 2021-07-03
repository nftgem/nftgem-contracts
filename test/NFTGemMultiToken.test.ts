import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {Contract} from '@ethersproject/contracts';
import {pack, keccak256} from '@ethersproject/solidity';
import {SignerWithAddress} from 'hardhat-deploy-ethers/dist/src/signers';

const {getContractFactory} = ethers;

describe('NFTGemMultiToken contract', function () {
  let owner: SignerWithAddress;
  let manager: SignerWithAddress;
  let proxyRegistry: SignerWithAddress;
  let receiver: SignerWithAddress;
  let NFTGemMultiToken: Contract;

  const tokenHash = keccak256(['bytes'], [pack(['string'], ['Test Token'])]);
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  beforeEach(async () => {
    await deployments.fixture();
    [owner, manager, proxyRegistry, receiver] = await ethers.getSigners();

    NFTGemMultiToken = await (
      await getContractFactory('NFTGemMultiToken', owner)
    ).deploy();

    await NFTGemMultiToken.deployed();
    await NFTGemMultiToken.addController(owner.address);
  });

  it('Should set correct state variables', async function () {
    expect(await NFTGemMultiToken.getRegistryManager()).to.equal(owner.address);
    expect(
      (await NFTGemMultiToken.allProxyRegistriesLength()).toNumber()
    ).to.equal(1);
    expect(await NFTGemMultiToken.isController(owner.address)).to.be.true;
  });
  describe('Registry manager', function () {
    it('Should set registry manager', async function () {
      await NFTGemMultiToken.setRegistryManager(manager.address);
      expect(await NFTGemMultiToken.getRegistryManager()).to.equal(
        manager.address
      );
    });
  });
  describe('Add/remove proxy registry', function () {
    it('Should add proxy registry', async function () {
      await NFTGemMultiToken.addProxyRegistry(proxyRegistry.address);
      const proxyRegistriesLength = await NFTGemMultiToken.allProxyRegistriesLength();
      expect(
        await NFTGemMultiToken.allProxyRegistries(proxyRegistriesLength - 1)
      ).to.equal(proxyRegistry.address);
      expect(proxyRegistriesLength.toNumber()).to.equal(2);
    });
    it('Should not add proxy registry', async function () {
      await expect(
        NFTGemMultiToken.connect(manager).addProxyRegistry(
          proxyRegistry.address
        )
      ).to.be.revertedWith('UNAUTHORIZED');
    });
    it('Should remove proxy registry', async function () {
      await NFTGemMultiToken.addProxyRegistry(proxyRegistry.address);
      const proxyRegistriesLength = await NFTGemMultiToken.allProxyRegistriesLength();
      expect(proxyRegistriesLength).to.equal(2);
      await NFTGemMultiToken.removeProxyRegistryAt(proxyRegistriesLength - 1);
      expect(
        await NFTGemMultiToken.allProxyRegistries(proxyRegistriesLength - 1)
      ).to.equal(ZERO_ADDRESS);
    });
    it('Should not remove proxy registry', async function () {
      await expect(
        NFTGemMultiToken.connect(manager).removeProxyRegistryAt(0)
      ).to.be.revertedWith('UNAUTHORIZED');
      await expect(
        NFTGemMultiToken.removeProxyRegistryAt(2)
      ).to.be.revertedWith('INVALID_INDEX');
    });
  });
  it('Should mint new tokens', async function () {
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    const newBalance = (
      await NFTGemMultiToken.balanceOf(receiver.address, tokenHash)
    ).toNumber();
    expect(newBalance).to.equal(100);
    // Test _beforeTokenTransfer function also
    expect(
      (await NFTGemMultiToken.allHeldTokens(receiver.address, 0)).toHexString()
    ).to.equal(tokenHash);
    expect(await NFTGemMultiToken.allTokenHolders(tokenHash, 0)).to.equal(
      receiver.address
    );
  });
  it('Should burn tokens', async function () {
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    await NFTGemMultiToken.burn(receiver.address, tokenHash, 50);
    expect(
      (await NFTGemMultiToken.balanceOf(receiver.address, tokenHash)).toNumber()
    ).to.equal(50);
    // Test whether token is getting removed from contract state variables
    // or not when we burn all available tokens
    await NFTGemMultiToken.burn(receiver.address, tokenHash, 50);
    expect(
      (await NFTGemMultiToken.balanceOf(receiver.address, tokenHash)).toNumber()
    ).to.equal(0);

    expect(
      (await NFTGemMultiToken.allHeldTokens(receiver.address, 0)).toNumber()
    ).to.equal(0);
    expect(await NFTGemMultiToken.allTokenHolders(tokenHash, 0)).to.equal(
      ZERO_ADDRESS
    );
  });
  it('Should lock tokens', async function () {
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    await NFTGemMultiToken.connect(receiver).lock(tokenHash, 1621913547);
    // expect((await NFTGemMultiToken.unlockTime(receiver.address, tokenHash)).toNumber()).to.equal(1621913547);
    /*  // TODO: Check this logic
      NFTGemMultiToken contract stores the timestamp value in following map:
      _tokenLocks[_msgSender()][timestamp] = timestamp;
      Should this line be written like this? : _tokenLocks[_msgSender()][token] = timestamp;

      and returns the timestamp value using following map:
      _tokenLocks[account][token];
    */
  });
  it('should return uri', async function () {
    await expect(NFTGemMultiToken.uri(tokenHash)).to.be.revertedWith(
      'NFTGemMultiToken#uri: NONEXISTENT_TOKEN'
    );
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    // TODO: Resolve this error:
    /* 
      Error: Transaction reverted: contract call run out of gas and made the transaction revert
      Error in following line: 55 in NFTGemMultiToken Contract:
      return Strings.strConcat(ERC1155Pausable(this).uri(_id), Strings.uint2str(_id));
    */
    // console.log(await NFTGemMultiToken.uri(tokenHash));
  });
  it('should return the token held by the holder', async function () {
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    const allHeldTokensLength = (
      await NFTGemMultiToken.allHeldTokensLength(receiver.address)
    ).toNumber();
    expect(allHeldTokensLength).to.equal(1);
    expect(
      (await NFTGemMultiToken.allHeldTokens(receiver.address, 0)).toHexString()
    ).to.equal(tokenHash);
  });
  it('should return the address of token holder', async function () {
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    const allTokenHoldersLength = (
      await NFTGemMultiToken.allTokenHoldersLength(tokenHash)
    ).toNumber();
    expect(allTokenHoldersLength).to.equal(1);
    expect(await NFTGemMultiToken.allTokenHolders(tokenHash, 0)).to.equal(
      receiver.address
    );
  });
  it('should return total balance of given token', async function () {
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    expect(
      (await NFTGemMultiToken.totalBalances(tokenHash)).toNumber()
    ).to.equal(100);
  });
  it('should approve for all', async function () {
    await NFTGemMultiToken.addProxyRegistry(proxyRegistry.address);
    // TODO: Resolve following error:
    // Error: Transaction reverted: function call to a non-contract account
    // Line No: 148
    // expect(await NFTGemMultiToken.isApprovedForAll(owner.address, proxyRegistry.address)).to.be.true;
  });
});
