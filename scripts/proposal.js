/* eslint-disable @typescript-eslint/no-var-requires */
require('dotenv').config();
const { BigNumber } = require('ethers');
const { formatEther, parseEther } = require('ethers/lib/utils');
const hre = require('hardhat');
require('@nomiclabs/hardhat-waffle');

(async function main() {

  const waitForMined = async (transactionHash) => {
    return new Promise(resolve => {
      const _checkReceipt = async () => {
        const txReceipt = await await hre.ethers.provider.getTransactionReceipt(
          transactionHash
        );
        return txReceipt && txReceipt.blockNumber ? txReceipt : null;
      };
      const interval = setInterval(() => {
        _checkReceipt().then(r => {
          if (r) { clearInterval(interval);
            resolve(true); }
        });
      }, 500);
    });
  };

  const {ethers, deployments} = hre;
  const networkId = await hre.getChainId();
  const {utils, getContractAt} = ethers;
  const {get} = deployments;
  const [sender] = await hre.ethers.getSigners();

  // get proposal factory
  const gemGov = await getContractAt(
    'NFTGemGovernor',
    (await get('NFTGemGovernor')).address,
    sender
  );
  const proposalFac = await getContractAt(
    'ProposalFactory',
    (await get('ProposalFactory')).address,
    sender
  );
  // get proposal factory
  const multitoken = await getContractAt(
    'NFTGemMultiToken',
    (await get('NFTGemMultiToken')).address,
    sender
  );
  // get proposal factory
  const feeManager = await getContractAt(
    'NFTGemFeeManager',
    (await get('NFTGemFeeManager')).address,
    sender
  );

  // craete fund project proposal
  // let tx = await gemGov.createFundProjectProposal(
  //   sender.address,
  //   sender.address,
  //   sender.address,
  //   'deploy new contracts',
  //   parseEther('20000'),
  //   {gasLimit: '400000'}
  // );
  // await waitForMined(tx.hash);

  // get proposal factory
  const apropo = await proposalFac.allProposals(0, {gasLimit: '400000'});

  const prop = await ethers.getContractAt('Proposal', apropo, sender, {
    libraries: {
      ProposalsLib: (await get('ProposalsLib')).address,
      GovernanceLib: (await get('GovernanceLib')).address,
    },
  });

  // let tx = await prop.fund({
  //   value: parseEther('1'),
  //   gasLimit: '400000'
  // });
  // await waitForMined(tx.hash);

  let tx = await multitoken.safeTransferFrom(
    sender.address,
    apropo,
    apropo,
    (await multitoken.balanceOf(sender.address, apropo)).toString(),
    0,
    { gasLimit: '400000' }
  );
  await waitForMined(tx.hash);

  tx = await prop.execute({
    gasLimit: '400000'
  });
  await waitForMined(tx.hash);


  // const allTokensLen = await poolContract.allTokenHashesLength();
  // console.log('allTokensLen', allTokensLen.toNumber());

  // const gems = [], claims = [];

  // for(var i = 0; i < ~~(allTokensLen.toNumber() / 20); i++) {
  //   const results = await tokenPoolQuerier.getOwnedTokens(poolContract.address, atoken, atarget, i, 20, { gasLimit: 500000});
  //   results.claims.forEach(c => { if(!c.eq(0)) claims.push(c); });
  //   results.gems.forEach(c => { if(!c.eq(0)) gems.push(c); });
  //   console.log('claims', claims);
  //   console.log('gems', gems);
  // }
  //   const tx = await sender.sendTransaction({
  //     to: th,
  //     value: parseEther('5'),
  //     gasLimit: BigNumber.from('400000'),
  //     nonce: n++,
  //   });


// const bo = await multitoken.balanceOf('0xce1DB19c21da28B70FB663EC0c49C8C8e69a16DA', 0);
// const b2o = await multitoken.balanceOf('0xce1DB19c21da28B70FB663EC0c49C8C8e69a16DA', 1);
// console.log('bo', bo.toString());
// console.log('gems',  formatEther(b2o.toString()));

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

  // get governor

  // c reate
})();
