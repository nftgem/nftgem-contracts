/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const {BigNumber} = require('ethers');
const {parseEther} = require('ethers/lib/utils');
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

(async function main() {
  const {ethers, deployments} = hre;
  const {get} = deployments;
  const {getContractAt} = ethers;

  const target = ethers.utils.getAddress(
    '0x217b7DAB288F91551A0e8483aC75e55EB3abC89F'
  );
  const [sender] = await hre.ethers.getSigners();

  const multitoken = await getContractAt(
    'NFTGemMultiToken',
    (await get('NFTGemMultiToken')).address,
    sender
  )
  const gemPoolFactory = await getContractAt(
    'NFTGemPoolFactory',
    (await get('NFTGemPoolFactory')).address,
    sender
  )
  const tokenPoolQuerier = await getContractAt(
    'TokenPoolQuerier',
    (await get('TokenPoolQuerier')).address,
    sender
  )


  const waitForMined = async (transactionHash) => {
    return new Promise((resolve) => {
      const _checkReceipt = async () => {
        const txReceipt = await hre.ethers.provider.getTransactionReceipt(
          transactionHash
        );
        return txReceipt && txReceipt.blockNumber ? txReceipt : null;
      };
      const interval = setInterval(() => {
        _checkReceipt().then((r) => {
          if (r) {
            clearInterval(interval);
            resolve(true);
          }
        });
      }, 500);
    });
  };

  const waitFor = async (n) => {
    return new Promise((resolve) => setTimeout(resolve, n * 1000));
  };


  const results = await tokenPoolQuerier.getOwnedTokens('0x3eD40cbeA5C347aEB6280211d4D623d6C8193f29', multitoken.address, target);
  console.log(results);


  // const poolContracts = await Promise.all(
  //   gemPools.map((gp) =>
  //     ethers.getContractAt('NFTComplexGemPoolData', gp, sender, {
  //       libraries: {
  //         ComplexPoolLib: '0xE9Ef69f136d9885164a9d1002D74Bf3785Ca889c',
  //       },
  //     })
  //   )
  // );

  // const poolSettings = await Promise.all(
  //   poolContracts.map((pc) => pc.settings())
  // );
  // console.log(poolSettings);

  // const allTokenHashes = {};
  // const gemPools = await gemPoolFactory.nftGemPools();

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
  //   Object.values(allTokenHashes).map((th) => multitoken.tokenHolders(target))
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
  //   const tx = await sender.sendTransaction({
  //     to: th,
  //     value: parseEther('5'),
  //     gasLimit: BigNumber.from('400000'),
  //     nonce: n++,
  //   });

  //   console.log(`${th} ${tx.hash}`);
  //   await waitForMined(tx.hash);
  //   await waitFor(5);
  // }
  // await waitFor(15);
})();
