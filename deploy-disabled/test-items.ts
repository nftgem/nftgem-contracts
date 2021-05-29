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
  const waitForTime = BigNumber.from(networkId).eq(1337) ? 1 : 15;

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

  const itemPrice = '0.0001';

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

  const getWrappedGemTokenAddress = async (sym: string) => {
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
      const gtAddr  = await getWrappedGemTokenAddress(`W${symbol}`);
      console.log(`address: ${gtAddr}`);

      // create the unigem20 pool
      const baseSym = await dc.WETH9.symbol();
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
  };

  /**
   ******************************************************************************
   */

  await createPool(
    'MINA',
    'Minion 1',
    parseEther(itemPrice),
    30,
    90,
    32,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MINB',
    'Minion 2',
    parseEther(itemPrice),
    30,
    90,
    16,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MINC',
    'Minion 3',
    parseEther(itemPrice),
    30,
    90,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MIND',
    'Minion 4',
    parseEther(itemPrice),
    30,
    90,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MINE',
    'Minion 5',
    parseEther(itemPrice),
    30,
    90,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'MINF',
    'Minion 6',
    parseEther(itemPrice),
    30,
    90,
    12,
    0,
    '0x0000000000000000000000000000000000000000'
  );

  await createPool(
    'UBOSSA',
    'Underboss 1',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINA'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINB'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINC'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MIND'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINE'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINF'), 3, 0, 1, true, false],
    ]
  );

  await createPool(
    'UBOSSB',
    'Underboss 2',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINA'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINB'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINC'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MIND'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINE'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINF'), 3, 0, 1, true, false],
    ]
  );

  await createPool(
    'UBOSSC',
    'Underboss 3',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINA'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINB'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINC'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MIND'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINE'), 3, 0, 1, true, false],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MINF'), 3, 0, 1, true, false],
    ]
  );

  await createPool(
    'LBOSSA',
    'LevelBoss 1',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSA'), 3, 0, 2, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSB'), 3, 0, 2, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSC'), 3, 0, 2, true, true],
    ]
  );

  await createPool(
    'LBOSSB',
    'LevelBoss 2',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSA'), 3, 0, 2, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSB'), 3, 0, 2, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSC'), 3, 0, 2, true, true],
    ]
  );

  await createPool(
    'LBOSSC',
    'LevelBoss 3',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSA'), 3, 0, 2, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSB'), 3, 0, 2, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSC'), 3, 0, 2, true, true],
    ]
  );

  await createPool(
    'MBOSS',
    'MidBoss',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('LBOSSA'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('LBOSSB'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('LBOSSC'), 3, 0, 1, true, true],
    ]
  );

  await createPool(
    'BOSS',
    'The Final Challenge',
    parseEther(itemPrice),
    30,
    90,
    4,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('MBOSS'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('LBOSSA'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('LBOSSB'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('LBOSSC'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSA'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSB'), 3, 0, 1, true, true],
      [dc.NFTGemMultiToken.address, await getGemPoolAddress('UBOSSC'), 3, 0, 1, true, true],
    ]
  );

  let addr = await createPool(
    'OCW',
    'One-claim Wonder',
    parseEther(itemPrice),
    5,
    5,
    65536 * 65536,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );
  let c = await getPoolContract(addr);
  let tx = await c.setMaxQuantityPerClaim(1);
  await waitForMined(tx.hash);
  tx = await c.setMaxClaimsPerAccount(1);
  await waitForMined(tx.hash);

  addr = await createPool(
    'TQO',
    'Two Quantities One Claim',
    parseEther(itemPrice),
    5,
    5,
    65536 * 65536,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );
  c = await getPoolContract(addr);
  tx = await c.setMaxQuantityPerClaim(2);
  await waitForMined(tx.hash);
  tx = await c.setMaxClaimsPerAccount(1);
  await waitForMined(tx.hash);

  addr = await createPool(
    'OQT',
    'One Quantity Two Claims',
    parseEther(itemPrice),
    5,
    5,
    65536 * 65536,
    0,
    '0x0000000000000000000000000000000000000000',
    []
  );
  c = await getPoolContract(addr);
  tx = await c.setMaxQuantityPerClaim(1);
  await waitForMined(tx.hash);
  tx = await c.setMaxClaimsPerAccount(2);
  await waitForMined(tx.hash);

  await createPool(
    'LINT',
    'Unattainable Lint',
    parseEther(itemPrice),
    5,
    5,
    65536 * 65536,
    0,
    '0x0000000000000000000000000000000000000000',
    [
      [
        dc.NFTGemMultiToken.address,
        '0x0000000000000000000000000000000000000000',
        2,
        2,
        1,
        true,
        false,
      ],
    ]
  );

  // we are done!
  console.log('Deploy complete\n');
  const nbal = await sender.getBalance();
  console.log(`${chainId} ${thisAddr} : ${formatEther(nbal)}`);
  console.log(`spent : ${formatEther(bal.sub(nbal))}`);

  // await dc.NFTGemWrappedERC20Governance.wrap('1000');

  // dc.NFTGemMultiToken.safeTransferFrom(
  //   sender.address,
  //   '0x217b7DAB288F91551A0e8483aC75e55EB3abC89F',
  //   2,
  //   1,
  //   0
  // );

  await waitFor(3);

  return dc;
};

func.dependencies = ['Deploy'];
export default func;
