#!/bin/bash

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

usage() {
    echo "$0 -a <ACCOUNT> -c <CONTRIBUTIONS_ADDRESS> -w <LEAD_CONTRIBUTOR_WALLET> -p <PROJECT1,PROJECT2,...>"
}

### ARGUMENT PARSING
while getopts a:c:w:p:h option
do
    case "${option}"
    in
        a) ACCOUNT=${OPTARG};;
        c) CONTRACT=${OPTARG};;
        w) WALLET=${OPTARG};;
        p) PROJECTS=${OPTARG};;
        h) usage; exit_success;;
        \?) usage; exit_error;;
    esac
done

[ -z $ACCOUNT ] && exit_error "-a option is mandatory"
[ -z $CONTRACT ] && exit_error "-c option is mandatory"
[ -z $WALLET ] && exit_error "-w option is mandatory"
[ -z $PROJECTS ] && exit_error "-p option is mandatory"

for project in `echo $PROJECTS | tr , ' '`
do
    send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRACT --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs $project $WALLET"
done
