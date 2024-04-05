# ⛓️🔗⛓️ Template for IBC enabled Solidity contracts

This repo provides a starter project to build [IBC](https://github.com/cosmos/ibc) enabled Solidity contracts that connect rollups to one another Polymer Hub, through the [vIBC core contracts](https://github.com/open-ibc/vibc-core-smart-contracts).

The repository is a _GitHub template_ repository so you can click "Use this template" to create your own project repository without having the entire commit history of the template.

![GitHub template](./img/gh_template.png)

## 📚 Documentation

There's some basic information here in the README but a more comprehensive documentation can be found in [the official Polymer documentation](https://docs.polymerlabs.org/docs/category/build-ibc-dapps-1).

## 📋 Prerequisites

The repo is **compatible with both Hardhat and Foundry** development environments.

- Have [git](https://git-scm.com/downloads) installed
- Have [node](https://nodejs.org) installed (v18+)
- Have [Foundry](https://book.getfoundry.sh/getting-started/installation) installed (Hardhat will be installed when running `npm install`)
- Have [just](https://just.systems/man/en/chapter_1.html) installed (recommended but not strictly necessary)

You'll need some API keys from third party's:

- [Optimism Sepolia](https://optimism-sepolia.blockscout.com/account/api-key) and [Base Sepolia](https://base-sepolia.blockscout.com/account/api-key) Blockscout Explorer API keys
- Have an [Alchemy API key](https://docs.alchemy.com/docs/alchemy-quickstart-guide) for OP and Base Sepolia

Some basic knowledge of all of these tools is also required, although the details are abstracted away for basic usage.

## 🧰 Install dependencies

To compile your contracts and start testing, make sure that you have all dependencies installed.

From the root directory run:

```bash
just install
```

to install the [vIBC core smart contracts](https://github.com/open-ibc/vibc-core-smart-contracts) as a dependency.

Additionally Hardhat will be installed as a dev dependency with some useful plugins. Check `package.json` for an exhaustive list.

> Note: In case you're experiencing issues with dependencies using the `just install` recipe, check that all prerequisites are correctly installed. If issues persist with forge, try to do the individual dependency installations...

## ⚙️ Set up your environment variables

Convert the `.env.example` file into an `.env` file. This will ignore the file for future git commits as well as expose the environment variables. Add your private keys and update the other values if you want to customize (advanced usage feature).

```bash
cp .env.example .env
```

This will enable you to sign transactions with your private key(s). If not added, the scripts from the justfile will fail.

### Configuration file

The configuration file is where all important data is stored for the just commands and automation. We strive to make direct interaction with the config file as little as possible.

By default the configuration file is stored at root as `config.json`.

However, it is recommended to split up different contracts/projects in the same repo into different config file in case you want to switch between them.

Store alternate config files in the /config directory and set

```sh
# .env file
CONFIG_PATH='config.json'
```

to use a different config file.

### Obtaining testnet ETH

The account associated with your private key must have both Base Sepolia and Optimism Sepolia ETH. To obtain the testnet ETH visit:

- [Optimism Sepolia Faucet](https://www.alchemy.com/faucets/optimism-sepolia)
- [Base Sepolia Faucet](https://www.alchemy.com/faucets/base-sepolia)

## 💻 Develop Contract

### 1. Compile contracts

```bash
just compile
```

### 2. Deploy PolymerERC20 on OP

```bash
npx hardhat run scripts/deploy/deployPolyERC20.js --network optimism
```
### 3. Update config
Append PolymerERC20 contract address was deployed from step 2 to `.env`

```bash
POLY_ERC20_ADDRESS = <POLYMER_ERC20_ADDRESS>
```

### 4. Set config contract XGamingUC and PolyERC721UC

```bash
just set-contracts optimism XGamingUC true && just set-contracts base PolyERC721UC true
```

### 5. Deploy contract XGamingUC and PolyERC721UC

```bash
just deploy optimism base
```
### 6. Add operator for XGameIng

###
```bash 
npx hardhat run scripts/deploy/updateXGamingConfig.js  --network optimism 
```

## 🕹️ Interaction with the contracts

Run scripts to interaction with contract

### 1. Facet random PolymerERC20

```bash
npx hardhat run scripts/XGaming/faucet.js
```

### 2. Buy a NFT

```bash
npx hardhat run scripts/XGaming/buyNft.js
```
### 3. Buy random a NFT

```bash
npx hardhat run scripts/XGaming/buyRandomNft.js
```
### 4. Burn NFT 

```bash
npx hardhat run scripts/XGaming/burnNft.js --network base
```