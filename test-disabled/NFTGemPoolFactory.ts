import hre from 'hardhat';
import { expect } from "chai";

const ethers = { hre }

let NFTGemLib:any
let UniswapLib:any

describe("NFTGemPoolFactory", function() {

  before(async function() {

    NFTGemLib = await (await ethers.getContractFactory("NFTGemLib")).deploy();
    UniswapLib = await (await ethers.getContractFactory("UniswapLib")).deploy();

    await NFTGemLib.deployed();
    await UniswapLib.deployed();

  });

  it("Should create", async function() {
    const NFTGemPoolFactory = await ethers.getContractFactory("NFTGemPoolFactory", {
      libraries: {
        "NFTGemLib": NFTGemLib.address,
        "UniswapLib": NFTGemLib.address
      }
    });
    const greeter = await NFTGemPoolFactory.deploy();

    await greeter.deployed();
    expect((await greeter.allNFTGemPoolsLength()).toNumber()).to.equal(0);

  });
});
