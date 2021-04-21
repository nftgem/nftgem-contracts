const ethers = require('ethers');
const {pack, keccak256} = require('@ethersproject/solidity');
const bn = require('bn.js');

function diff(i) {
  let n = new bn(Math.pow(2, i));
  let m = new bn(`1`).notn(256).shln(i).add(n);
  if (bn.isEven(m)) {
    // m = m.add(new bn(1));
  }
}

for (var i = 0; i < 1000; i++) {
  let countFound = 0;
  for (var j = 0; j < 100000; j++) {
    const hashToTest = new bn(
      keccak256(
        ['bytes'],
        [pack(['string', 'uint256', 'uint256'], ['someseedinfo', i, j])]
      )
    );
    if (hashToTest.and(diff(i)).eq(hashToTest)) {
      countFound++;
    }
  }
  console.log(
    `${diff(i).toString(16)} found ${countFound} out of 1000 ${
      countFound / 1000
    }%`
  );
}
