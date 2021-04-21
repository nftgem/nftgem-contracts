const ethers = require('ethers');
let oneEth = ethers.BigNumber.from(ethers.utils.parseEther('1'));
for (var i = 0; i < 10000; i++, oneEth = oneEth.add(oneEth.div(256)))
  if (i % 1000 == 0)
    console.log(`256 ${i}  ${ethers.utils.formatEther(oneEth.toString())}`);

oneEth = ethers.BigNumber.from(ethers.utils.parseEther('1'));
for (i = 0; i < 10000; i++, oneEth = oneEth.add(oneEth.div(512)))
  if (i % 1000 == 0)
    console.log(`512 ${i}  ${ethers.utils.formatEther(oneEth.toString())}`);

oneEth = ethers.BigNumber.from(ethers.utils.parseEther('1'));
for (i = 0; i < 10000; i++, oneEth = oneEth.add(oneEth.div(1024)))
  if (i % 1000 == 0)
    console.log(`1024 ${i}  ${ethers.utils.formatEther(oneEth.toString())}`);

oneEth = ethers.BigNumber.from(ethers.utils.parseEther('1'));
for (i = 0; i < 10000; i++, oneEth = oneEth.add(oneEth.div(2048)))
  if (i % 1000 == 0)
    console.log(`2048 ${i}  ${ethers.utils.formatEther(oneEth.toString())}`);

oneEth = ethers.BigNumber.from(ethers.utils.parseEther('1'));
for (i = 0; i < 10000; i++, oneEth = oneEth.add(oneEth.div(4096)))
  if (i % 1000 == 0)
    console.log(`4096 ${i}  ${ethers.utils.formatEther(oneEth.toString())}`);
