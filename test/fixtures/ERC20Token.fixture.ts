import {deployments} from 'hardhat';

export const createERC20Token = deployments.createFixture(async ({ethers}, data: any) => {
  const wallet = ethers.Wallet.createRandom();
  const ERC20Token = await (
    await ethers.getContractFactory('TestToken', data.owner)
  ).deploy('TST', 'Test Token');
  await ERC20Token.deployed();
  ERC20Token.connect(wallet);

  return {
    ERC20Token,
  };
});
