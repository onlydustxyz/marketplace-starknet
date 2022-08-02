<p align="center">
    <img width="150" src="resources/img/logo.png">
</p>
<div align="center">
  <h1 align="center">deathnote-contributions-starknet</h1>
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
  
  <h3 align="center">Death Note starknet contracts to manage contributors and contributions</h3>
</div>

> ## ⚠️ WARNING! ⚠️
>
> This repo contains highly experimental code.
> Expect rapid iteration.

## 🎟️ Description

This repository contains the code for starknet smart contracts:

* **registry**: To register a contributor into the platform (mint a profile and associate its different user ids like github)
* **profile**: The non-transferrable NFT that will be used to identify contributions of a given contributor
* **contributions**: The list of contributions

## 🎗️ Prerequisites

Install [protostar](https://docs.swmansion.com/protostar/) version 0.2.1 or above.

```bash
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash
```

## 📦 Installation

## 🔬 Usage

## 🌡️ Testing

```bash
protostar test
```

or use [Protostar Test Explorer](https://marketplace.visualstudio.com/items?itemName=abuisset.vscode-protostar-test-adapter) vscode extension.

## 🚀 Deploy

First, you need to have an OpenZeppelin-compatible account deployed on the target network.
[This can be done with Braavos](https://braavos.notion.site/Using-StarkNet-CLI-with-your-Braavos-Private-Key-c4e1acc0425e4a0089bd9aaa4b1aee3e).

Add the account address, public key and private key to the `~/.starknet_accounts/starknet_open_zeppelin_accounts.json` file,
under an alias of your choice (eg. `local_admin` or `staging_admin`).

Then, just execute the deploy script:

```bash
./scripts/deploy.sh -a local_admin -p local
```

This script will look for a build/deployed_contracts.txt file to get what is already deployed.

Once the deployments are done, the build/deployed_contracts.txt file is created/updated accordingly.

If you want to re-deploy something, just remove the corresponding line from build/deployed_contracts.txt and run the script again.

## 🏗 Contributing

Pull requests are welcome, please check our [contribution guidelines](./CONTRIBUTING.md) .

## 📄 License

**deathnote-contributions-starknet** is released under the [MIT](LICENSE).

## PROD

### MEP1

* supprimer le CONTRIBUTION_CLASS_HASH du fichier deployed_contracts_prod.txt
* verifier que contributions.cairo importe bien les nouvelles fonctions de migration
* verifier qu'il n'y a PAS de script de migration (contributions_migration.cairo)
* executer le script de deploiement afin de MAJ l'implem du proxy de contributions

### MEP2

* tester une migration qui revert
