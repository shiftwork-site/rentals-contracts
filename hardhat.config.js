require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-truffle5");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomiclabs/hardhat-etherscan");

const dotenv = require("dotenv");
dotenv.config();

module.exports = {
  networks:
  {
    goerli: {
      url: "https://eth-goerli.public.blastapi.io",
      accounts: [process.env.GOERLI_PRIVATE_KEY],
    },
    mainnet: {
      url: process.env.ALCHEMY_HTTP,
      accounts: [process.env.MAINNET_PRIVATE_KEY],
      gas: 3500000

    }
  },

  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY
    }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
};
