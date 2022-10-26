#!/bin/bash

### TOOLS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
. $SCRIPT_DIR/tools.sh 

### FUNCTIONS
deploy_account() {
	ACCOUNT_OPT=`[ $# -eq 1 ] && echo "--account $1"`
	execute starknet_local new_account $ACCOUNT_OPT

    ACCOUNT_ADDRESS=`tail -n 10 logs.json | sed -n 's@Account address: \(.*\)@\1@p'`
	curl -H "Content-Type: application/json" -X POST --data "{\"address\":\"$ACCOUNT_ADDRESS\", \"amount\":100000000000000000000}" "$DEVNET_URL/mint"

	execute starknet_local deploy_account $ACCOUNT_OPT
}

### MAIN
if [ ! -f $ACCOUNT_DIR/starknet_open_zeppelin_accounts.json ]
then
	log_info "Deploying accounts"
	deploy_account 
	deploy_account ctf_admin
else
	log_info "Accounts already deployed"
fi

exit_success
