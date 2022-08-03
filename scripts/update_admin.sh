#!/bin/bash

### CONSTANTS

NEW_ADMIN=0x379fe3432e28f6a53afbd9d90251a46eff164f845fad5e2418c466f14ed727a

CONTRIBUTIONS_ADDRESS=0x011d60f34d8e7b674833d86aa85afbe234baad95ae6ca3d9cb5c4bcd164b7358
REGISTRY_ADDRESS=0x04e16efc9bc2d8d40ecb73d3d69e3e2d6f0fc3e2e6e9b7601310fdfa7dd6c7cf
PROFILE_ADDRESS=0x004176872b71583cb9bc3671db28f26e7f426a7c0764613a0838bb99ef373aa6


### FUNCTIONS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
. $SCRIPT_DIR/logging.sh # Logging utilities
. $SCRIPT_DIR/tools.sh   # script utilities

# wait for a transaction to be received
# $1 - transaction hash to check
wait_for_acceptance() {
    tx_hash=$1
    print -n $(magenta "Waiting for transaction to be accepted")
    while true 
    do
        tx_status=`starknet tx_status --hash $tx_hash $NETWORK_OPT | sed -n 's@^.*"tx_status": "\(.*\)".*$@\1@p'`
        case "$tx_status"
            in
                NOT_RECEIVED|RECEIVED|PENDING) print -n  $(magenta .);;
                REJECTED) return 1;;
                ACCEPTED_ON_L1|ACCEPTED_ON_L2) return 0; break;;
                *) exit_error "\nUnknown transaction status '$tx_status'";;
            esac
            sleep 2
    done
}

# send a transaction
# $* - command line to execute
# return The contract address
send_transaction() {
    transaction=$*

    while true
    do
        execute $transaction || exit_error "Error when sending transaction"
        
        tx_hash=`sed -n 's@Transaction hash: \(.*\)@\1@p' logs.json`

        wait_for_acceptance $tx_hash

        case $? in
            0) log_success "\nTransaction accepted!"; break;;
            1) log_warning "\nTransaction rejected!"; ask "Do you want to retry";;
        esac
    done || exit_error

    echo $tx_hash
}


### ARGUMENT PARSING
while getopts a:p:h option
do
    case "${option}"
    in
        a) ACCOUNT=${OPTARG};;
        h) usage; exit_success;;
        \?) usage; exit_error;;
    esac
done


# Change proxy admin of Contributions
echo "---------------------------------------------------------------------------------"
echo "Change proxy admin of Contributions to $NEW_ADMIN"
tx_hash=`send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function set_proxy_admin --inputs $NEW_ADMIN"` || exit_error


# Add admin to the Profile contract
echo "---------------------------------------------------------------------------------"
echo "Add admin to the Profile contract to $NEW_ADMIN"
tx_hash=`send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $PROFILE_ADDRESS --abi build/profile_abi.json --function grant_admin_role --inputs $NEW_ADMIN"` || exit_error


# Add admin to the Registry contract
echo "---------------------------------------------------------------------------------"
echo "Add admin to the Registry contract to $NEW_ADMIN"
tx_hash=`send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $REGISTRY_ADDRESS --abi build/registry_abi.json --function grant_admin_role --inputs $NEW_ADMIN"` || exit_error


# Add admin to the Contribution contract
echo "---------------------------------------------------------------------------------"
echo "Add admin to the Contribution contract to $NEW_ADMIN"
tx_hash=`send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function grant_admin_role --inputs $NEW_ADMIN"` || exit_error


