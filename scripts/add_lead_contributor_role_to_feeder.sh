#!/bin/bash

### CONSTANTS

# Old Feeder account
FEEDER=0x05313c775f9dad3963786dd16710dc26de7da82ad68c6c65ef6a1062445e4321

CONTRIBUTIONS_ADDRESS=0x04aa3b2b258388a58ed429795ab56a9cd9613152755ec317f5c6bee2294e2264


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
        tx_status=`starknet tx_status --hash $tx_hash --network alpha-goerli | sed -n 's@^.*"tx_status": "\(.*\)".*$@\1@p'`
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


send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 521676353 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 204005121 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 522927651 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 499061005 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 499081602 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 493591124 $FEEDER"
