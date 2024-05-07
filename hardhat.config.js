require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-foundry");
require('@openzeppelin/hardhat-upgrades');
require('dotenv').config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: !process.env.DEBUG,
        runs: 200,
      },
    }
  },
  networks: {
    ganache: {
      chainId: 1337,
      url: "http://127.0.0.1:8545"
    },
  },
};
