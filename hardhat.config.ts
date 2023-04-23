import "hardhat-gas-reporter";
import "hardhat-deploy";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomicfoundation/hardhat-chai-matchers";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

const coinMarketCapKey = process.env.COIN_MARKET_CAP_KEY ?? "NO_COIN_MARKET_CAP_KEY";

const config: HardhatUserConfig = {
    gasReporter: {
        currency: "USD",
        token: "ETH",
        enabled: true,
        coinmarketcap: coinMarketCapKey,
        excludeContracts: [],
        src: "./contracts",
    },
    paths: {
        artifacts: "./artifacts",
        cache: "./cache",
        sources: "./contracts",
        deployments: "./deployments",
    },
    networks: {
        hardhat: {
            blockGasLimit: 10000000,
        },
    },
    solidity: {
        compilers: [
            {
                version: "0.8.17",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 200,
                    },
                },
            },
        ],
        settings: {
            outputSelection: {
                "*": {
                    "*": ["storageLayout"],
                },
            },
        },
    },
    mocha: {
        timeout: 100000000,
    },
};

export default config;
