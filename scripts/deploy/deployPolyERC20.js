const hre = require("hardhat");

async function main() {
  const networkName = hre.network.name;
  const myContract = await hre.ethers.deployContract('PolyERC20', []);
  await myContract.waitForDeployment();

  console.log(
    `Contract PolyERC20 deployed to ${myContract.target} on network ${networkName}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
