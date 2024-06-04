# Climeta Contracts

## Summary

## Install

Install the contract dependencies:

```bash
forge install OpenZeppelin/openzeppelin-contracts-upgradeable --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
```

Then add in the remappings in foundry.toml


## Style Guide

* Pragma statements
* Import statements
* Events
* Errors
* Interfaces
* Libraries
* Contracts

* Type declarations
* State variables
* Events
* Errors
* Modifiers
* Functions

```mermaid
sequenceDiagram
    participant User
    participant LoginPage
    participant NFTWallet
    User->>LoginPage: Navigate
    LoginPage->>User: Login Button 
    User->>NFTWallet: Connect Wallet
    NFTWallet->>LoginPage: Fetch User's NFTs
    LoginPage->>User: Choose NFT for Login
    User->>NFTWallet: Selected NFT
    NFTWallet->>LoginPage: Verify Ownership of NFT
    LoginPage->>User: Login Successful
```
