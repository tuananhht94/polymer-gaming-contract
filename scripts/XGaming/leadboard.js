const hre = require('hardhat');
const { getConfigPath } = require('../private/_helpers.js');
const { getIbcApp } = require('../private/_vibc-helpers.js');

async function main() {
    const networkName = hre.network.name;
    // Get the contract type from the config and get the contract
    const ibcApp = await getIbcApp(networkName);

    const leaderboard = await ibcApp.getLeaderboard()
    console.log(leaderboard);

    const topPlayers = await ibcApp.getTopPlayers(10)
    console.log(topPlayers);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
