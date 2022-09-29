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

## Create a pre-configured dump file for local testing

To perform end-to-end testing in the marketplace-backend, we need to create a `starknet-devnet` dump file with all the necessary contracts deployed.

### 1. Build and the `starknet-devnet` docker image

Note: specify the `BASE_TAG` to be used depending on your CPU (`latest` or `latest-arm`)

```sh
cd scripts/docker
DUMP_PATH=$MARKETPLACE_BACKEND_ROOT/scripts/docker/dev BASE_TAG=latest-arm docker-compose up --build -d 
```

With the `--seed 0` option, a list of 10 accounts have been deployed.
Those accounts will be used as follow:
```
Account #0 : Admin
Account #1 : Sign-up backend account
Account #2 : Marketplace backend account
Account #3 : Not used
Account #4 : Not used
Account #5 : Not used
Account #6 : Not used
Account #7 : Not used
Account #8 : Not used
Account #9 : Not used
Account #10: Not used
```

To see the accounts details, check the docker logs:
```sh
docker logs docker_starknet-devnet_1
```

### 2. Deploy a 2d-nonce account for each backend:

Follow the instructions on `onlydustxyz/starknet-accounts` repository and provide the `marketplace-backend` account public key as input and re-run the same process for the `signup` account.

Add some ETH in them to be able to send transactions later:
```bash
curl -H "Content-Type: application/json" -X POST --data '{"address":"0x061e0474b7cdbfaf15e54e97c2bb632d365ccf553320a7db511c07950250948e", "amount":100000000000000000000}' "http://127.0.0.1:5050/mint"
curl -H "Content-Type: application/json" -X POST --data '{"address":"0x0488cbf60f5d972aeee11bb8bcce7cecb8023f7a7cc5f2c7f6d9f53c8f68ff17", "amount":100000000000000000000}' "http://127.0.0.1:5050/mint"
```

Check the account balance with the following command:
```bash
curl -H "Content-Type: application/json" -X GET "http://127.0.0.1:5050/account_balance?address=0x061e0474b7cdbfaf15e54e97c2bb632d365ccf553320a7db511c07950250948e"
curl -H "Content-Type: application/json" -X GET "http://127.0.0.1:5050/account_balance?address=0x0488cbf60f5d972aeee11bb8bcce7cecb8023f7a7cc5f2c7f6d9f53c8f68ff17"
```

### 3. Configure the back-ends to use the 2d nonce accounts
Update the `ACCOUNT_ADDRESS` environment variable in `.env.example` file for **both** repositories.

Update the `.env.local` file in `marketplace-starknet` repository.

### 4. Deploy the smart contracts
First, remove the local cache file:
```sh
[ -f build/deployed_contracts_local.txt ] && rm build/deployed_contracts_local.txt
```

Then, follow the instructions in `Deploy` section

Once contracts are deployed, update the `.env.example` file of **both** repositories with the correct smart contracts addresses.

### 5. Request the dump file
```bash
curl -X POST http://localhost:5050/dump -d '{ "path": "/tmp/dump.pkl" }' -H "Content-Type: application/json"
```

and wait for the dump file to be complete:
```
watch du $MARKETPLACE_BACKEND_ROOT/scripts/docker/dev/dump.pkl
```

🎉 Congratulations, the dump file is ready!

### 6. Stop starknet-devnet process

```sh
docker-compose down
```


## 🏗 Contributing

Pull requests are welcome, please check our [contribution guidelines](./CONTRIBUTING.md).

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
