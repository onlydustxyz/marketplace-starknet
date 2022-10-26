#!/bin/bash

### TOOLS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
. $SCRIPT_DIR/tools.sh 

### MAIN
log_info "Cleaning-up"
[ -f $ACCOUNT_DIR/starknet_open_zeppelin_accounts.json ] && rm $ACCOUNT_DIR/starknet_open_zeppelin_accounts.json
[ -f $SCRIPT_DIR/contracts.env ] && rm $SCRIPT_DIR/contracts.env

exit_success
