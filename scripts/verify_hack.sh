#!/bin/bash

### TOOLS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
. $SCRIPT_DIR/tools.sh 
. $SCRIPT_DIR/contracts.env

### FUNCTIONS
verify() {
	execute starknet_local call \
		--address $CONTRIBUTION_CONTRACT_ADDRESS \
		--abi ./build/hack_me_abi.json \
		--function hacked
}

### MAIN
log_info "Verifying hack"

verify && green "🎉🎉🎉 Well done !" || exit_error "Try again ;-)"