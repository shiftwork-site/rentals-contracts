require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-truffle5");
require("hardhat-contract-sizer");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomicfoundation/hardhat-chai-matchers");
require("@nomicfoundation/hardhat-verify");

const dotenv = require("dotenv");
dotenv.config();

module.exports = {
  networks:
  {
    goerli: {
      url: "https://eth-goerli.public.blastapi.io",
      accounts: [process.env.TESTNET_PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gas: 5000000, //units of gas you are willing to pay, aka gas limit
      gasPrice: 50000000000, //gas is typically in units of gwei, but you must enter it as wei here

    },
    mainnet: {
      url: process.env.ALCHEMY_HTTP,
      accounts: [process.env.MAINNET_PRIVATE_KEY],
      gas: 350000000,

    },
    sepolia: {
      url: process.env.ALCHEMY_SEPOLIA_HTTP,
      accounts: [process.env.TESTNET_PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gas: 50000000000, //units of gas you are willing to pay, aka gas limit
      gasPrice: 50000000000, //gas is typically in units of gwei, but you must enter it as wei here

    },
    polygonMumbai: {
      url: "https://polygon-mumbai-bor-rpc.publicnode.com/",
      accounts: [process.env.MAINNET_PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gas: 50000000000, //units of gas you are willing to pay, aka gas limit
      gasPrice: 50000000000, //gas is typically in units of gwei, but you must enter it as wei here
    },
    optimism: {
      url: "https://mainnet.optimism.io",
      accounts: [process.env.MAINNET_PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gas: 50000000000, //units of gas you are willing to pay, aka gas limit
      gasPrice: 50000000000, //gas is typically in units of gwei, but you must enter it as wei here

    },
    "optimism-sepolia": {
      url: "https://sepolia.optimism.io",
      accounts: [process.env.TESTNET_PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gas: 5000000, //units of gas you are willing to pay, aka gas limit
      gasPrice: 50000000000, //gas is typically in units of gwei, but you must enter it as wei here

    },
    holesky: {
      url: "https://rpc.holesky.ethpandaops.io",
      accounts: [process.env.TESTNET_PRIVATE_KEY],
      allowUnlimitedContractSize: true,
      gas: 5000000, //units of gas you are willing to pay, aka gas limit
      gasPrice: 50000000000, //gas is typically in units of gwei, but you must enter it as wei here

    }
  },

  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY,
      mainnet: process.env.ETHERSCAN_API_KEY,
      optimism: process.env.OP_ETHERSCAN_API_KEY,
      "optimism-sepolia": process.env.OP_ETHERSCAN_API_KEY,
      polygonMumbai: process.env.ETHERSCAN_MUMBAI_API_KEY
    },
    customChains: [
      {
        network: "optimism-sepolia",
        chainId: 11155420,
        urls: {
          apiURL: "http://api-sepolia-optimism.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io/"
        }
      }
    ]
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,

    },
  },
};
