/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const {BigNumber} = require('ethers');
const {parseEther} = require('ethers/lib/utils');
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

const waitForMined = async (transactionHash) => {
  return new Promise((resolve) => {
    const _checkReceipt = async () => {
      const txReceipt = await hre.ethers.provider.getTransactionReceipt(
        transactionHash
      );
      return txReceipt && txReceipt.blockNumber ? txReceipt : null;
    };
    setInterval(() => {
      _checkReceipt().then((r) => {
        if (r) {
          resolve(true);
        }
      });
    }, 500);
  });
};

const waitFor = async (n) => {
  return new Promise((resolve) => setTimeout(resolve, n * 1000));
};

(async function main() {
  const {ethers} = hre;

  const agemPoolFactory = ethers.utils.getAddress(
    process.env.GEM_POOL_FACTORY || '0x543e712c216CF072992d58059e6716873040549B'
  );

  const amultiToken = ethers.utils.getAddress(
    process.env.MULTITOKEN || '0x047a12B6Be14AEE36B3346CC27fF5b4C9A8d03F9'
  );

  const target = ethers.utils.getAddress(
    '0x2a0524733D006b909f144A788Cdf7F1C6851331F'
  );

  const deployParams = {
    log: true,
    libraries: {
      ComplexPoolLib: '0xd8bf0D941FC41e44f383d78183807669c230BDed',
    },
  };
  const NFTGemPoolFactory = await ethers.getContractFactory(
    'NFTGemPoolFactory',
    deployParams
  );
  const NFTGemMultiToken = await ethers.getContractFactory('NFTGemMultiToken');
  const gemPoolFactory = await NFTGemPoolFactory.attach(agemPoolFactory);
  const multitoken = await NFTGemMultiToken.attach(amultiToken);

  const gemPools = await gemPoolFactory.nftGemPools();

  const [sender] = await hre.ethers.getSigners();

  const heldTokensByHash = {};
  const heldTokens = await multitoken.heldTokens(target);
  const htInfo = await Promise.all(
    heldTokens.map((ht) => multitoken.getTokenData(ht))
  );
  htInfo.forEach((ht, i) => (heldTokensByHash[heldTokens[i]] = ht));

  // console.log(gemPools);
  // console.log(heldTokens);

  const poolContracts = await Promise.all(
    gemPools.map((gp) =>
      ethers.getContractAt('NFTComplexGemPoolData', gp, sender, {
        libraries: {
          ComplexPoolLib: '0xE9Ef69f136d9885164a9d1002D74Bf3785Ca889c',
        },
      })
    )
  );
  const poolSettingsByAddress = {};
  const poolSettings = await Promise.all(
    poolContracts.map((pc) => pc.settings())
  );
  poolSettings.forEach((ps, i) => (poolSettingsByAddress[gemPools[i]] = ps));

  console.log(heldTokensByHash);
  console.log(poolSettingsByAddress);

  setInterval(async () => {
    const gems = [];
    const claims = [];

    const heldTokens = await multitoken.heldTokens(target);
    const htInfo = await Promise.all(
      heldTokens.map((ht) => multitoken.getTokenData(ht))
    );
    htInfo.forEach((ht, i) => {
      if (ht.tokenType === 1) claims.push(heldTokens[i].toHexString());
      else if (ht.tokenType === 2) gems.push(heldTokens[i].toHexString());
    });
    console.log('claims', claims);
    console.log('gems', gems);
  }, 5000);

  // const allTokenHashes = {};

  // const tokenHashes = await Promise.all(
  //   poolContracts.map((pc) => pc.tokenHashes())
  // );
  // tokenHashes.forEach((thList) => {
  //   thList.forEach((th) => {
  //     if (!th.eq(0) && !th.eq(1)) allTokenHashes[th.toHexString()] = th;
  //   });
  // });

  // const allTokenHolders = {};
  // const holders = await Promise.all(
  //   Object.values(allTokenHashes).map((th) => multitoken.tokenHolders(th))
  // );
  // holders.forEach((thList) => {
  //   thList.forEach((th) => {
  //     if (th != '0x0000000000000000000000000000000000000000')
  //       allTokenHolders[th] = th;
  //   });
  // });

  // let n = 4423;
  // for (var i = 3; i < Object.values(allTokenHolders).length; i++) {
  //   const th = Object.values(allTokenHolders)[i];
  //   // const tx = await sender.sendTransaction({
  //   //   to: th,
  //   //   value: parseEther('5'),
  //   //   gasLimit: BigNumber.from('400000'),
  //   //   nonce: n++,
  //   // });

  //   console.log(`${th} ${tx.hash}`);
  //   await waitForMined(tx.hash);
  //   await waitFor(5);
  // }
  // await waitFor(15);
})();
