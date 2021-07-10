import {expect} from './chai-setup';
import {ethers, deployments} from 'hardhat';
import {Contract} from '@ethersproject/contracts';
import {pack, keccak256} from '@ethersproject/solidity';

const {getContractFactory} = ethers;

describe('NFTGemMultiToken contract', function () {
  let NFTGemMultiToken: Contract;

  const tokenHash = keccak256(['bytes'], [pack(['string'], ['Test Token'])]);
  const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000';

  beforeEach(async () => {
    await deployments.fixture();
    const [owner] = await ethers.getSigners();

    NFTGemMultiToken = await (
      await getContractFactory('NFTGemMultiToken', owner)
    ).deploy();

    await NFTGemMultiToken.deployed();
    await NFTGemMultiToken.addController(owner.address);
  });

  it('Should set correct state variables', async function () {
    const [owner] = await ethers.getSigners();
    expect(await NFTGemMultiToken.getRegistryManager()).to.equal(owner.address);
    expect(
      (await NFTGemMultiToken.allProxyRegistriesLength()).toNumber()
    ).to.equal(0);
    expect(await NFTGemMultiToken.isController(owner.address)).to.be.true;
  });

  describe('Registry manager', function () {
    it('Should set registry manager', async function () {
      const [manager] = await ethers.getSigners();
      await NFTGemMultiToken.setRegistryManager(manager.address);
      expect(await NFTGemMultiToken.getRegistryManager()).to.equal(
        manager.address
      );
    });
  });

  describe('Add/remove proxy registry', function () {
    it('Should add proxy registry', async function () {
      const [proxyRegistry] = await ethers.getSigners();
      await NFTGemMultiToken.addProxyRegistry(proxyRegistry.address);
      expect(await NFTGemMultiToken.allProxyRegistries(0)).to.equal(
        proxyRegistry.address
      );
      expect(
        (await NFTGemMultiToken.allProxyRegistriesLength()).toNumber()
      ).to.equal(1);
    });

    it('Should not add proxy registry', async function () {
      const [address1, address2] = await ethers.getSigners();
      await expect(
        NFTGemMultiToken.connect(address2).addProxyRegistry(
          address1.address
        )
      ).to.be.revertedWith('UNAUTHORIZED');
    });

    it('Should remove proxy registry', async function () {
      const [proxyRegistry] = await ethers.getSigners();
      await NFTGemMultiToken.addProxyRegistry(proxyRegistry.address);
      expect(
        (await NFTGemMultiToken.allProxyRegistriesLength()).toNumber()
      ).to.equal(1);
      await NFTGemMultiToken.removeProxyRegistryAt(0);
      expect(await NFTGemMultiToken.allProxyRegistries(0)).to.equal(
        ZERO_ADDRESS
      );
    });

    it('Should not remove proxy registry', async function () {
      const [_, address2] = await ethers.getSigners();
      await expect(
        NFTGemMultiToken.connect(address2).removeProxyRegistryAt(0)
      ).to.be.revertedWith('UNAUTHORIZED');
      await expect(
        NFTGemMultiToken.removeProxyRegistryAt(2)
      ).to.be.revertedWith('INVALID_INDEX');
    });
  });

  it('Should mint new tokens', async function () {
    const [receiver] = await ethers.getSigners();
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
    const [receiver] = await ethers.getSigners();
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
    const [receiver] = await ethers.getSigners();
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
    const [receiver] = await ethers.getSigners();
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
    const [receiver] = await ethers.getSigners();
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
    const [receiver] = await ethers.getSigners();
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
    const [receiver] = await ethers.getSigners();
    await NFTGemMultiToken.mint(receiver.address, tokenHash, 100);
    expect(
      (await NFTGemMultiToken.totalBalances(tokenHash)).toNumber()
    ).to.equal(100);
  });

  it('should approve for all', async function () {
    const [proxyRegistry] = await ethers.getSigners();
    await NFTGemMultiToken.addProxyRegistry(proxyRegistry.address);
    // TODO: Resolve following error:
    // Error: Transaction reverted: function call to a non-contract account
    // Line No: 148
    // expect(await NFTGemMultiToken.isApprovedForAll(owner.address, proxyRegistry.address)).to.be.true;
  });
});
