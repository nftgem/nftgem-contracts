const {pack, keccak256} = require('@ethersproject/solidity');

module.exports = async (hre) => {

  const {ethers, deployments} = hre;
  const [sender] = await ethers.getSigners();
  const networkId = await hre.getChainId();
  const {getContractAt, BigNumber} = ethers;
  const {get} = deployments;
  const deployParams = {
    from: sender.address,
    log: true,
    libraries: {},
  };

  console.log(sender.address);

  const NFTComplexGemPool = await ethers.getContractFactory(
    'NFTGemPool',
    deployParams
  );

  const waitForMined = async (transactionHash) => {
    return new Promise((resolve) => {
      setInterval(() => {
        const _checkReceipt = async () => {
          const txReceipt = await hre.ethers.provider.getTransactionReceipt(
            transactionHash
          );
          return txReceipt && txReceipt.blockNumber ? txReceipt : null;
        };
        _checkReceipt().then(async(r) => {
          if (r) {
            const txReceipt = await hre.ethers.provider.getTransactionReceipt(
              transactionHash
            );
            console.log(txReceipt.hash);
            resolve(true);
          }
        });
      }, 500);
    });
  };

  const getDeployedContracts = async () => {
    const ret = {
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
  };

  const deployedContracts = await getDeployedContracts();

  const getPoolAddress = async (sym) => {
    return await deployedContracts.NFTGemPoolFactory.getNFTGemPool(
      keccak256(['bytes'], [pack(['string'], [sym])])
    );
  };

  const getPoolContract = async (addr) => {
    return NFTComplexGemPool.attach(addr);
  };

  const createPool = async (
    symbol,
    name,
    price,
    min,
    max,
    diff,
    maxClaims,
    allowedToken
  ) => {
    let poolAddr = await getPoolAddress(symbol);
    if (BigNumber.from(poolAddr).eq(0)) {
      console.log(`Creating ${name} (${symbol}) pool...`);
      const tx = await deployedContracts.NFTGemGovernor.createSystemPool(
        symbol,
        name,
        price,
        min,
        max,
        diff,
        maxClaims,
        allowedToken,
        {gasLimit: 600000}
      );
      console.log('createSystemPool',tx);
      await waitForMined(tx.hash);
      poolAddr = await getPoolAddress(symbol);
    }
    return await getPoolContract(poolAddr);
  };

  return {
    waitForMined, deployedContracts, getPoolAddress, getPoolContract, createPool
  }
};
