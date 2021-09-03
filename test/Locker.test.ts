import { Contract } from "ethers";
import { expect } from "./chai-setup";
import { pack, keccak256 } from "@ethersproject/solidity";
import { ethers } from "hardhat";
import {
  setupNftGemGovernor
} from './fixtures/Governance.fixture';

describe('Locker Test Suite', function () {
  let Locker: Contract;
  let NFTGemMultiToken: any;
  const tokenHash = keccak256(['bytes'], [pack(['string'], ['Test Token'])]);
  beforeEach(async () => {
    // Deploy Locker Contract on each test iteration
    Locker = await (await ethers.getContractFactory('Locker')).deploy();
    const setupNftGemGovernorResult = await setupNftGemGovernor();
    NFTGemMultiToken = setupNftGemGovernorResult.NFTGemMultiToken;
    const [sender] = await ethers.getSigners();
    // Mint token to sender to make sure the sender have enough balance
    await NFTGemMultiToken.mint(sender.address, tokenHash, 100);
    await NFTGemMultiToken.connect(sender).setApprovalForAll(Locker.address, true);
  })
  it('Drop Off', async function () {
    await Locker.dropOff(
      NFTGemMultiToken.address,
      tokenHash,
      NFTGemMultiToken.address,
      tokenHash,
      5);
    const LockerContent = await Locker.contents(tokenHash);
    expect(LockerContent).to.not.be.undefined;
    expect(LockerContent.awardTokenAddress).to.be.equal(NFTGemMultiToken.address);
    expect(LockerContent.unlockTokenAddress).to.be.equal(NFTGemMultiToken.address);
    expect(LockerContent.awardTokenHash).to.be.equal(tokenHash);
    expect(LockerContent.unlockTokenHash).to.be.equal(tokenHash);
  });
});
