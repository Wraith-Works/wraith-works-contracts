require('hardhat-gas-reporter');
require('hardhat-deploy');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-etherscan');
require('@nomicfoundation/hardhat-chai-matchers');

const { resolve } = require('path');

const { config: dotenvConfig } = require('dotenv');

dotenvConfig({ path: resolve(__dirname, './.env') });

const coinMarketCapKey = process.env.COIN_MARKET_CAP_KEY ?? 'NO_COIN_MARKET_CAP_KEY';

const config = {
    gasReporter: {
        currency: 'USD',
        token: 'MATIC',
        enabled: true,
        coinmarketcap: coinMarketCapKey,
        excludeContracts: [],
        src: './contracts',
    },
    paths: {
        artifacts: './artifacts',
        cache: './cache',
        sources: './contracts',
        deployments: './deployments',
    },
    networks: {
        hardhat: {
            blockGasLimit: 10000000,
        },
    },
    solidity: {
        compilers: [
            {
                version: '0.8.17',
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
                '*': {
                    '*': ['storageLayout'],
                },
            },
        },
    },
    mocha: {
        timeout: 100000000,
    },
};

module.exports = config;
