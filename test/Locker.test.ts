import { keccak256 } from "ethers/lib/utils";
import { ethers } from "hardhat";

describe('A', function () {
  it('Drop Off', async function () {
    const [unlocker, awardToken] = await ethers.getSigners();
    const Locker = await (await ethers.getContractFactory('Locker')).deploy();
    await Locker.dropOff(
      unlocker,
      keccak256(await unlocker.getAddress()),
      awardToken,
      keccak256(await awardToken.getAddress()),
      5);
  })
});
