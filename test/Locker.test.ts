import { Contract } from "ethers";
import { expect } from "./chai-setup";
import { ethers } from "hardhat";
import {
  setupNftGemGovernor
} from './fixtures/Governance.fixture';
import { SignerWithAddress } from "hardhat-deploy-ethers/dist/src/signers";

describe('Locker Test Suite', function () {
  let locker: Contract;
  let sender: SignerWithAddress;
  let thief: SignerWithAddress;
  let receiver: SignerWithAddress;
  let NFTGemMultiToken: any;
  const unlockToken = '1';
  const awardToken = '2';
  beforeEach(async () => {
    const setupNftGemGovernorResult = await setupNftGemGovernor();
    NFTGemMultiToken = setupNftGemGovernorResult.NFTGemMultiToken;
    [sender, receiver, thief] = await ethers.getSigners();
    // Mint token to sender to make sure the sender have enough balance
    await NFTGemMultiToken.mint(sender.address, awardToken, 100);
    await NFTGemMultiToken.mint(receiver.address, unlockToken, 1000);
  })
  it('Drop Off', async function () {
    // Deploy Locker Contract on each test iteration
    locker = await (await ethers.getContractFactory('Locker')).deploy();
    await NFTGemMultiToken.setApprovalForAll(locker.address, true);
    await locker.dropOff(
      NFTGemMultiToken.address,
      unlockToken,
      NFTGemMultiToken.address,
      awardToken,
      5, {
      from: sender.address,
    });
    const lockerContent = await locker.contents(unlockToken);
    expect(lockerContent).to.not.be.undefined;
    expect(lockerContent.awardTokenAddress).to.be.equal(NFTGemMultiToken.address);
    expect(lockerContent.unlockTokenAddress).to.be.equal(NFTGemMultiToken.address);
    expect(lockerContent.awardTokenHash).to.be.equal(awardToken);
    expect(lockerContent.unlockTokenHash).to.be.equal(unlockToken);
  });

  it('Pick Up', async function () {
    locker = await (await ethers.getContractFactory('Locker')).deploy();
    await NFTGemMultiToken.setApprovalForAll(locker.address, true);
    // We need to dropOff locker first before picking up the content inside.
    await locker.dropOff(
      NFTGemMultiToken.address,
      unlockToken,
      NFTGemMultiToken.address,
      awardToken,
      50,
    )
    //Picking up the locker award with receiver account
    await locker.connect(receiver).pickUpTokenWithKey(unlockToken);
    const lockerContent = await locker.contents(unlockToken);
    expect(lockerContent.awardQty).to.be.equal(0);
    // Check if the receiver has actually receive the award
    expect(await NFTGemMultiToken.balanceOf(receiver.address, unlockToken)).to.equal(1050);
  });

  it('Unathorized Pick Up', async function () {
    locker = await (await ethers.getContractFactory('Locker')).deploy();
    await NFTGemMultiToken.setApprovalForAll(locker.address, true);
    await NFTGemMultiToken.mint(thief.address, '3', 10);
    // We need to dropOff locker first before picking up the content inside.
    await locker.dropOff(
      NFTGemMultiToken.address,
      unlockToken,
      NFTGemMultiToken.address,
      awardToken,
      5,
    )
    // Intentionally Picking up locker content with the wrong unlock key and expect the contract to throw an error
    expect(await locker.connect(thief).pickUpTokenWithKey('3')).to.throw('Unlock token missmatched');
  });
});
