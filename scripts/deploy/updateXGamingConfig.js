const hre = require('hardhat');
const { getConfigPath } = require('../private/_helpers');
const { getIbcApp } = require('../private/_vibc-helpers.js');

async function main() {
    const accounts = await hre.ethers.getSigners();
    const networkName = hre.network.name;
    const ibcApp = await getIbcApp(networkName);
    await ibcApp.connect(accounts[0]).setPolyERC20Address(process.env.POLY_ERC20_ADDRESS);

    const polyERC20Factory = await hre.ethers.getContractFactory('PolyERC20');
    const polyERC20 = await polyERC20Factory.attach(process.env.POLY_ERC20_ADDRESS);
    await polyERC20.connect(accounts[0]).addOperator(ibcApp.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
