const {pack, keccak256} = require('@ethersproject/solidity');
const { formatEther, parseEther } = require('ethers/lib/utils');

module.exports = async (hre) => {

  const {ethers, deployments} = hre;
  const [sender] = await ethers.getSigners();
  const networkId = await hre.getChainId();
  const {getContractAt, BigNumber} = ethers;
  const chainId = (await ethers.provider.getNetwork()).chainId;
  const {get} = deployments;
  const deployParams = {
    from: sender.address,
    log: true,
    libraries: {
      ComplexPoolLib: (await get('ComplexPoolLib')).address
    },
  };

  console.log(`${chainId} ${sender.address} ${formatEther(await sender.getBalance())}`);

  const NFTComplexGemPool = await ethers.getContractFactory(
    'NFTComplexGemPool',
    deployParams
  );

  const waitForMined = async (transactionHash) => {
    const _checkReceipt = async () => {
      const txReceipt = await hre.ethers.provider.getTransactionReceipt(
        transactionHash
      );
      return txReceipt && txReceipt.blockNumber ? txReceipt : null;
    };
    return new Promise((resolve) => {
      const interval = setInterval(() => {
        _checkReceipt().then(async(r) => {
          if (r) {
            clearInterval(interval);
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
    allowedToken,
    inputRequirements
  ) => {
    let tx,
      created = false,
      nonce = BigNumber.from(0);
    if (BigNumber.from(chainId).eq(1337)) {
      price = parseEther('0.0001');
      min = 5;
      max = 5;
      diff = 65536 * 65536;
    }
    let poolAddr = await getPoolAddress(symbol);
    if (BigNumber.from(poolAddr).eq(0)) {
      console.log(`Creating ${name} (${symbol}) pool...`);
      tx = await deployedContracts.NFTGemGovernor.createSystemPool(
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
      const gpAddr = await getPoolAddress(symbol);
      console.log(`Creating wrapped ${name} (${symbol}) token...`);
      tx = await deployedContracts.ERC20GemTokenFactory.createItem(
        `W${symbol}`,
        `Wrapped ${name}`,
        gpAddr,
        deployedContracts.NFTGemMultiToken.address,
        18,
        {gasLimit: 5000000, nonce}
      );
      await waitForMined(tx.hash);
      nonce = nonce.add(1);
      poolAddr = await getPoolAddress(symbol);
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
    return await getPoolContract(symbol);
  };

  return {
    waitForMined, deployedContracts, getPoolAddress, getPoolContract, createPool
  }
};
