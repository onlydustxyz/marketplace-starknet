#!/bin/bash

### TOOLS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
. $SCRIPT_DIR/tools.sh 

### FUNCTIONS
declare_contract() {
	CONTRACT_PATH=$1

	execute starknet_local declare --account $ADMIN_ACCOUNT_NAME --contract $CONTRACT_PATH 
    tail -n 5 logs.json | sed -n 's@Contract class hash: \(.*\)@\1@p' 
}

deploy_contract() {
	CLASS_HASH=$1
	shift

	execute starknet_local deploy --account $ADMIN_ACCOUNT_NAME --class_hash $CLASS_HASH $@
    tail -n 5 logs.json | sed -n 's@Contract address: \(.*\)@\1@p' 
}

log_info "Declaring strategies"
COMPOSITE_CLASS_HASH=`declare_contract ./build/composite.json`
PROTECTION_CLASS_HASH=`declare_contract ./build/protection.json`
HACKME_CLASS_HASH=`declare_contract ./build/hack_me.json`

log_info "Deploying contract"
CONTRIBUTION_CLASS_HASH=`declare_contract ./build/contribution.json`
CONTRIBUTION_CONTRACT_ADDRESS=`deploy_contract $CONTRIBUTION_CLASS_HASH --inputs $COMPOSITE_CLASS_HASH`

log_info "Initialize contract"
execute starknet_local invoke \
	--account $ADMIN_ACCOUNT_NAME \
	--address $CONTRIBUTION_CONTRACT_ADDRESS \
	--abi ./build/composite_abi.json \
	--function initialize \
	--inputs 2 $PROTECTION_CLASS_HASH $HACKME_CLASS_HASH

log_info "Contract to hack: $CONTRIBUTION_CONTRACT_ADDRESS"

(
	echo export CONTRIBUTION_CONTRACT_ADDRESS=$CONTRIBUTION_CONTRACT_ADDRESS
	echo export HACKME_CLASS_HASH=$HACKME_CLASS_HASH
) > $SCRIPT_DIR/contracts.env

exit_success
