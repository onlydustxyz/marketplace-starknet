<p align="center">
    <img width="150" src="resources/img/logo.png">
</p>
<div align="center">
  <h1 align="center">Hackable modular contracts</h1>
  <p align="center">
    <a href="https://discord.gg/onlydust">
        <img src="https://img.shields.io/badge/Discord-6666FF?style=for-the-badge&logo=discord&logoColor=white">
    </a>
    <a href="https://twitter.com/intent/follow?screen_name=onlydust_xyz">
        <img src="https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white">
    </a>
    <a href="https://contributions.onlydust.xyz/">
        <img src="https://img.shields.io/badge/Contribute-6A1B9A?style=for-the-badge&logo=notion&logoColor=white">
    </a>
  </p>
  
  <h3 align="center">Capture The Flag - Level 1</h3>
</div>

> ## ⚠️ WARNING! ⚠️
>
> This repo contains unsafe code aimed at being hacked.
> DO NOT USE !!!

## 🎟️ Description

This repository contains the contracts to hack
## 🎗️ Prerequisites

* `cairo-lang` 0.10.1
* docker-compose

## 📦 Installation
1. Clone this repository with recursive option and check-out the correct branch
```bash
git clone https://github.com/onlydustxyz/marketplace-starknet.git --recursive
git co ctf-level1
```

2. Start the docker and deploy the accounts
```bash
make start
```

3. Compile the smart contracts
```bash
make build
```

## 🚀 Deploy

Deploy and initialize the smart contract to hack
```bash
make deploy
```

## 🔬 Usage
To hack the contract, you need to store the value `1` in the storage of the [`hack_me`](./contracts/onlydust/marketplace/core/assignment_strategies/hack_me.cairo) module.
This strategy is called by the `validate` function of the [`Contribution`](./contracts/onlydust/marketplace/core/contribution.cairo) contract and is protected by the [`protection`](./contracts/onlydust/marketplace/core/assignment_strategies/protection.cairo) module.

Good luck!

## 🌡️ Testing
To verify if the contract has been hacked, run:
```bash
make verify
```

## 📄 License

**deathnote-contributions-starknet** is released under the [MIT](LICENSE).
