import { Contract } from "ethers";
import { expect } from "./chai-setup";
import { pack, keccak256 } from "@ethersproject/solidity";
import { ethers } from "hardhat";
import {
  setupNftGemGovernor
} from './fixtures/Governance.fixture';

describe('Locker Test Suite', function () {
  let locker: Contract;
  let NFTGemMultiToken: any;
  const tokenHash = keccak256(['bytes'], [pack(['string'], ['Test Token'])]);
  beforeEach(async () => {
    // Deploy Locker Contract on each test iteration
    locker = await (await ethers.getContractFactory('Locker')).deploy();
    const setupNftGemGovernorResult = await setupNftGemGovernor();
    NFTGemMultiToken = setupNftGemGovernorResult.NFTGemMultiToken;
    const [sender] = await ethers.getSigners();
    // Mint token to sender to make sure the sender have enough balance
    await NFTGemMultiToken.mint(sender.address, tokenHash, 100);
    await NFTGemMultiToken.connect(sender).setApprovalForAll(locker.address, true);
  })
  it('Drop Off', async function () {
    await locker.dropOff(
      NFTGemMultiToken.address,
      tokenHash,
      NFTGemMultiToken.address,
      tokenHash,
      5);
    const lockerContent = await locker.contents(tokenHash);
    expect(lockerContent).to.not.be.undefined;
    expect(lockerContent.awardTokenAddress).to.be.equal(NFTGemMultiToken.address);
    expect(lockerContent.unlockTokenAddress).to.be.equal(NFTGemMultiToken.address);
    expect(lockerContent.awardTokenHash).to.be.equal(tokenHash);
    expect(lockerContent.unlockTokenHash).to.be.equal(tokenHash);
  });

  it('Pick Up', async function () {
    console.log(await locker.contents(tokenHash));
    await locker.dropOff(
      NFTGemMultiToken.address,
      tokenHash,
      NFTGemMultiToken.address,
      tokenHash,
      5,
    )
    await locker.pickUpTokenWithKey(tokenHash);
    const lockerContent = await locker.contents(tokenHash);
    expect(lockerContent.awardQty).to.be.equal(0);
  });
});
