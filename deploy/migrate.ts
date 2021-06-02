import {formatEther, parseEther} from 'ethers/lib/utils';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {pack, keccak256} from '@ethersproject/solidity';
import {BigNumber, BigNumberish} from '@ethersproject/bignumber';
const func: any = async function (hre: HardhatRuntimeEnvironment) {
  const {ethers, deployments} = hre;
  const networkId = await hre.getChainId();
  const {getContractAt} = ethers;
  const {get} = deployments;
  const [sender] = await hre.ethers.getSigners();

  if(BigNumber.from(networkId).eq(1337) || BigNumber.from(networkId).eq(4002)) {
    console.log(`test deploy. No migration.`);
    return;
  }

  /**
   * @dev Wait for the given number of seconds and display balance
   */
  const waitFor = async (n: number) => {
    const nbal = await sender.getBalance();
    console.log(`${chainId} ${thisAddr} : spent ${formatEther(bal.sub(nbal))}`);
    return new Promise((resolve) => setTimeout(resolve, n * 1000));
  };

  const waitForMined = async (transactionHash: string) => {
    return new Promise((resolve) => {
      const _checkReceipt = async () => {
        const txReceipt = await await hre.ethers.provider.getTransactionReceipt(
          transactionHash
        );
        return txReceipt && txReceipt.blockNumber ? txReceipt : null;
      };
      const interval = setInterval(() => {
        _checkReceipt().then((r: any) => {
          if (r) {
            clearInterval(interval);
            resolve(true);
          }
        });
      }, 500);
    });
  };

  /**
   * @dev Load all deployed contracts
   */
  async function getDeployedContracts(sender: any) {
    const ret: any = {
      NFTGemGovernor: await getContractAt(
        'NFTGemGovernor',
        (await get('NFTGemGovernor')).address,
        sender
      ),
      NFTGemMultiToken: await getContractAt(
        'NFTGemMultiToken',
        (await get('NFTGemMultiToken')).address,
        sender
      ),
      NFTGemPoolFactory: await getContractAt(
        'NFTGemPoolFactory',
        (await get('NFTGemPoolFactory')).address,
        sender
      ),
      NFTGemFeeManager: await getContractAt(
        'NFTGemFeeManager',
        (await get('NFTGemFeeManager')).address,
        sender
      ),
      NFTGemWrapperFeeManager: await getContractAt(
        'NFTGemWrapperFeeManager',
        (await get('NFTGemWrapperFeeManager')).address,
        sender
      ),
      ProposalFactory: await getContractAt(
        'ProposalFactory',
        (await get('ProposalFactory')).address,
        sender
      ),
      ERC20GemTokenFactory: await getContractAt(
        'ERC20GemTokenFactory',
        (await get('ERC20GemTokenFactory')).address,
        sender
      ),
      Unigem20Factory: await getContractAt(
        'Unigem20Factory',
        (await get('Unigem20Factory')).address,
        sender
      ),
      Unigem1155Factory: await getContractAt(
        'Unigem1155Factory',
        (await get('Unigem1155Factory')).address,
        sender
      ),
      NFTGemWrappedERC20Governance: await getContractAt(
        'NFTGemWrappedERC20Governance',
        (await get('NFTGemWrappedERC20Governance')).address,
        sender
      ),
      NFTGemWrappedERC20Fuel: await getContractAt(
        'NFTGemWrappedERC20Fuel',
        (await get('NFTGemWrappedERC20Fuel')).address,
        sender
      ),
      WETH9: await getContractAt(
        'WETH9',
        (await get('WETH9')).address,
        sender
      ),
      MockProxyRegistry: await getContractAt(
        'MockProxyRegistry',
        (await get('MockProxyRegistry')).address,
        sender
      ),
      BulkTokenMinter: await getContractAt(
        'BulkTokenMinter',
        (await get('BulkTokenMinter')).address,
        sender
      ),
      TokenPoolQuerier: await getContractAt(
        'TokenPoolQuerier',
        (await get('TokenPoolQuerier')).address,
        sender
      ),
    };

    /**
     * @dev Load the network-specific DEX-adapters - Uniswap for ETH and FTM,
     * PancakeSwap for BNB, Pangolin for AVAX, or a Mock helper for testing
     */
    if (parseInt(networkId) === 1) {
      ret.SwapHelper = await getContractAt(
        'UniswapQueryHelper',
        (await get('UniswapQueryHelper')).address,
        sender
      );
    } else if (parseInt(networkId) === 250) {
      ret.SwapHelper = await getContractAt(
        'SushiSwapQueryHelper',
        (await get('SushiSwapQueryHelper')).address,
        sender
      );
    } else if (parseInt(networkId) === 43114) {
      ret.SwapHelper = await getContractAt(
        'PangolinQueryHelper',
        (await get('PangolinQueryHelper')).address,
        sender
      );
    } else if (parseInt(networkId) === 56) {
      ret.SwapHelper = await getContractAt(
        'PancakeSwapQueryHelper',
        (await get('PancakeSwapQueryHelper')).address,
        sender
      );
    } else {
      ret.SwapHelper = await getContractAt(
        'MockQueryHelper',
        (await get('MockQueryHelper')).address,
        sender
      );
    }
    return ret;
  }

  /**
   * @dev retrieve and display address, chain, balance
   */
  console.log('Bitgem deploy\n');
  const bal = await sender.getBalance();
  const thisAddr = await sender.getAddress();
  const chainId = (await ethers.provider.getNetwork()).chainId;

  console.log(`${chainId} ${thisAddr} : ${formatEther(bal)}`);
  const dc = await getDeployedContracts(sender);
  const baseSym = await dc.WETH9.symbol();

  const deployParams = {
    from: sender.address,
    log: true,
    libraries: {
      ComplexPoolLib: (await get('ComplexPoolLib')).address,
    },
  };
  const NFTComplexGemPool = await ethers.getContractFactory(
    'NFTComplexGemPool',
    deployParams
  );

  const getGemPoolAddress = async (sym: string) => {
    return await dc.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
  };

  const getGemTokenAddress = async (sym: string) => {
    return await dc.ERC20GemTokenFactory.getItem(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
  };

  const getUnigem20Address = async (address1: string, address2: string) => {
    return await dc.Unigem20Factory.getPair(address1, address2);
  };

  const getPoolContract = async (addr: string) => {
    return NFTComplexGemPool.attach(addr);
  };

  const createPool = async (
    symbol: string,
    name: string,
    price: BigNumberish,
    min: number,
    max: number,
    diff: number,
    maxClaims: number,
    allowedToken: string,
    inputRequirements?: any[]
  ) => {
    let tx,
      created = false,
      nonce = BigNumber.from(0);
    let poolAddr = await getGemPoolAddress(symbol);
    if (BigNumber.from(poolAddr).eq(0)) {

      // create the gem pool
      console.log(`Creating ${name} (${symbol}) pool...`);
      tx = await dc.NFTGemGovernor.createSystemPool(
        symbol,
        name,
        price,
        min,
        max,
        diff,
        maxClaims,
        allowedToken,
        {gasLimit: 5000000}
      );
      await waitForMined(tx.hash);
      nonce = BigNumber.from(tx.nonce).add(1);
      poolAddr = await getGemPoolAddress(symbol);
      console.log(`address: ${poolAddr}`);

      // create the wrapped erc20 gem contract
      console.log(`Creating wrapped ${name} (${symbol}) token...`);
      tx = await dc.ERC20GemTokenFactory.createItem(
        `W${symbol}`,
        `Wrapped ${name}`,
        poolAddr,
        dc.NFTGemMultiToken.address,
        18,
        dc.NFTGemWrapperFeeManager.address,
        {gasLimit: 5000000, nonce}
      );
      await waitForMined(tx.hash);
      nonce = nonce.add(1);
      const gtAddr  = await getGemTokenAddress(`W${symbol}`);
      console.log(`address: ${gtAddr}`);

      // create the unigem20 pool
      console.log(`Creating unigem20 pool for W${symbol} / ${baseSym}`);
      tx = await dc.Unigem20Factory.createPair(
        gtAddr,
        dc.WETH9.address,
        {gasLimit: 5000000, nonce}
      );
      await waitForMined(tx.hash);
      nonce = nonce.add(1);

      const ugAddress = await getUnigem20Address(gtAddr, dc.WETH9.address);
      console.log(`address: ${ugAddress}`);

      created = true;
    }
    const pc = await getPoolContract(poolAddr);
    const reqlen = created ? 0 : await pc.allInputRequirementsLength();
    if (
      inputRequirements &&
      inputRequirements.length &&
      inputRequirements.length > 0 &&
      inputRequirements.length > reqlen
    ) {
      for (
        let ii = 0;
        ii < inputRequirements.length;
        ii++, nonce = nonce.add(1)
      ) {
        if (ii < reqlen) {
          console.log(`updating complex requirements to ${name} (${symbol})`);
          if (nonce.eq(0)) {
            tx = await pc.updateInputRequirement(ii, ...inputRequirements[ii]);
            nonce = BigNumber.from(tx.nonce);
          } else {
            tx = await pc.updateInputRequirement(ii, ...inputRequirements[ii], {
              nonce,
            });
          }
        } else {
          console.log(`adding complex requirements to ${name} (${symbol})`);
          if (nonce.eq(0)) {
            tx = await pc.addInputRequirement(...inputRequirements[ii]);
            nonce = BigNumber.from(tx.nonce);
          } else {
            tx = await pc.addInputRequirement(...inputRequirements[ii], {
              nonce,
            });
          }
        }
        await waitForMined(tx.hash);
      }
    }
    return await getGemPoolAddress(symbol);
  }

  /**
   ******************************************************************************
   */

  // bitgem v0
  // const afactory = ethers.utils.getAddress(
  //   '0xe502EC3A0025417F61a9BD44F0fAfD4DE6d13C65'
  // );
  // const alegacyToken = ethers.utils.getAddress(
  //   '0x752cE5Afa66b9E215b6dEE9F7Dc1Ec2bf868E373'
  // );

  // bitgem.co
  // const afactory = ethers.utils.getAddress(
  //   '0xEACd93F1A5daa4a4aD3cACB812bEF88a3A7fa9ca'
  // );
  // const alegacyToken = ethers.utils.getAddress(
  //   '0x496FEC70974870dD7c2905E25cAd4BDE802938C7'
  // );

  // bitlootbox.com
  const afactory = ethers.utils.getAddress(
    '0x9c393955D39c3C7A80Fe6A11B0e4B834a2c5301e'
  );
  const alegacyToken = ethers.utils.getAddress(
    '0x481d559466a04EB3744832e02a05aB1AE68fEb17'
  );

  const oldFactory = await getContractAt('NFTGemPoolFactory', afactory, sender);
  const oldToken = await getContractAt('NFTGemMultiToken', alegacyToken, sender);
  const newToken = await getContractAt('NFTGemMultiToken', dc.NFTGemMultiToken.address, sender);
  const newFactory = dc.NFTGemPoolFactory;

  const tx = await newToken.addController(dc.BulkTokenMinter.address);
  await waitForMined(tx.hash);

  const gpLen = await oldFactory.allNFTGemPoolsLength();
  for (let gp = 0; gp < gpLen.toNumber(); gp++) {
    const gpAddr = await oldFactory.allNFTGemPools(gp);
    const oldData = await getContractAt('INFTGemPoolData', gpAddr, sender);
    const sym = await oldData.symbol();
    if (sym === 'ASTRO' || sym === 'MCU') {
      continue;
    }
    console.log(`processing pool symbol ${sym}`);
    let newGpAddr = await newFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
    if (BigNumber.from(newGpAddr).eq(0)) {
      newGpAddr = await createPool(
        sym,
        await oldData.name(),
        await oldData.ethPrice(),
        await oldData.minTime(),
        await oldData.maxTime(),
        await oldData.difficultyStep(),
        await oldData.maxClaims(),
        '0x0000000000000000000000000000000000000000'
      );
    }
    if (BigNumber.from(newGpAddr).eq(0)) {
      console.log(`cant create pool symbol ${sym}`);
      continue;
    }

    const pc = await getPoolContract(newGpAddr);
    const nextGemId = await oldData.mintedCount();
    const nextClaimId = await oldData.claimedCount();

    let tx = await pc.setNextIds(nextClaimId, nextGemId);
    await waitForMined(tx.hash);
    console.log(`${sym} next claim ${nextClaimId.toString()} next gem ${nextGemId.toString()}`);

    tx = await pc.addAllowedTokenSource(alegacyToken);
    await waitForMined(tx.hash);
    console.log(`${sym} added token source ${alegacyToken.toString()}`);

    //tx = await pc.setCategory(1);
  //  await waitForMined(tx.hash);
    console.log(`${sym} set category - 0`);
  }

  const allGovTokenHolders = await oldToken.allTokenHoldersLength(0);
  console.log(`num holders: ${allGovTokenHolders.toNumber()}`);

  let holders = [],
    govQuantities = [],
    fuelQuantities = []

  for (let i = 0; i < allGovTokenHolders.toNumber(); i++) {
    const thAddr = await oldToken.allTokenHolders(0, i);

    const th0Bal = await oldToken.balanceOf(thAddr, 0);
    const th1Bal = await oldToken.balanceOf(thAddr, 1);

    holders.push(thAddr);
    govQuantities.push(th0Bal);
    fuelQuantities.push(th1Bal);
    console.log(`${i} ${thAddr} ${th0Bal.toString()} ${formatEther(th1Bal.toString())}`);

    if(i % 10 === 0 && holders.length > 1) {
      const tx = await dc.BulkTokenMinter.bulkMintGovFuel(newToken.address, holders, govQuantities, fuelQuantities, {gasLimit: 5000000});
      await waitForMined(tx.hash);
      holders = []; govQuantities = []; fuelQuantities = [];
    }
  }

  if(holders.length > 0) {
    const tx = await dc.BulkTokenMinter.bulkMintGovFuel(newToken.address, holders, govQuantities, fuelQuantities, {gasLimit: 5000000});
    await waitForMined(tx.hash);
  }
  /**
   ******************************************************************************
   */

  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  await waitFor(15);

  return dc;
};

func.tags = ['Publish'];
func.dependencies = ['Deploy'];
export default func;
