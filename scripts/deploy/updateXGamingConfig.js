const hre = require('hardhat');
const { getConfigPath } = require('../private/_helpers');
const { getIbcApp } = require('../private/_vibc-helpers.js');

async function main() {
    const accounts = await hre.ethers.getSigners();
    const config = require(getConfigPath());
    const sendConfig = config.sendUniversalPacket;

    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
    const ibcApp = await getIbcApp(networkName);
    // Send the packet
    await ibcApp.connect(accounts[0]).setPolyERC20Address(process.env.POLY_ERC20_ADDRESS);

    const polyERC20 = await ethers.getContractAt('PolyERC20', process.env.POLY_ERC20_ADDRESS);
    await polyERC20.connect(accounts[0]).addOperator(ibcApp.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
