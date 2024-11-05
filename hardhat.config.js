require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

module.exports = {
  solidity: {
    version: "0.8.25",
    settings: {
      evmVersion: "cancun",
      optimizer: {
        enabled: !process.env.DEBUG,
        runs: 200,
      },
    }
  },
  networks: {
    anvil: {
      chainId: 31337,
      url: "http://127.0.0.1:8545"
    },
  },
};
