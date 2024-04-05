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

    // Do logic to prepare the packet

    // If the network we are sending on is optimism, we need to use the base port address and vice versa
    const destPortAddr = networkName === "optimism" ?
        config["sendUniversalPacket"]["base"]["portAddr"] :
        config["sendUniversalPacket"]["optimism"]["portAddr"];

    const channelId = sendConfig[`${networkName}`]["channelId"];
    const channelIdBytes = hre.ethers.encodeBytes32String(channelId);
    const timeoutSeconds = sendConfig[`${networkName}`]["timeout"];

    // Send the packet
    // console.log(await ibcApp.getRandomNumber(1, 10));
    // Send the packet
    const polyERC20 = await ethers.getContractAt('PolyERC20', process.env.POLY_ERC20_ADDRESS);
    await polyERC20.connect(accounts[0]).mint(accounts[0].address, hre.ethers.parseEther("1000"));
    await polyERC20.connect(accounts[0]).approve(ibcApp.target, hre.ethers.parseEther("10000"));
    const tx = await ibcApp.connect(accounts[0]).buyNFT(destPortAddr, channelIdBytes, timeoutSeconds, 1);
    console.log(tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
