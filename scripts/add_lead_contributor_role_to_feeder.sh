#!/bin/bash

### CONSTANTS

# Old Feeder account
FEEDER=0x06ec9a30f0b9ffec60fca0ed83a3c550c3f616d2311130b008e42f454e23e61d

CONTRIBUTIONS_ADDRESS=0x011d60f34d8e7b674833d86aa85afbe234baad95ae6ca3d9cb5c4bcd164b7358


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


send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 508773198 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 444220622 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 493591124 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 501233690 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 476401778 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 481932781 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 420209573 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 486660536 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 480776993 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 493552406 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 510361047 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 418545583 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 510292638 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 457388175 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 510616270 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 511068225 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 412532737 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 504661472 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 499061005 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 498695724 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 455638351 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 510105950 $FEEDER"
send_transaction "starknet invoke --account $ACCOUNT --network alpha-goerli --address $CONTRIBUTIONS_ADDRESS --abi build/contributions_abi.json --function add_lead_contributor_for_project --inputs 420197620 $FEEDER"
