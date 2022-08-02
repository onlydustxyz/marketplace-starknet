#!/bin/bash

### CONSTANTS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
ROOT=`readlink -f $SCRIPT_DIR/..`
CACHE_FILE_BASE=$ROOT/build/deployed_contracts
STARKNET_ACCOUNTS_FILE=$HOME/.starknet_accounts/starknet_open_zeppelin_accounts.json
PROTOSTAR_TOML_FILE=$ROOT/protostar.toml

### FUNCTIONS
. $SCRIPT_DIR/logging.sh # Logging utilities
. $SCRIPT_DIR/tools.sh   # script utilities

# print the script usage
usage() {
    print "$0 [-a ADMIN_ACCOUNT] [-p PROFILE]"
}

# build the protostar project
build() {
    log_info "Building project to generate latest version of the ABI"
    execute protostar build
    if [ $? -ne 0 ]; then exit_error "Problem during build"; fi
}

# get the account address from the account alias in protostar accounts file
# $1 - account alias (optional). __default__ if not provided
get_account_address() {
    [ $# -eq 0 ] && account=__default__ || account=$1
    grep $account $STARKNET_ACCOUNTS_FILE -A3 -m1 | sed -n 's@^.*"address": "\(.*\)".*$@\1@p'
}

# get the network option from the profile in protostar config file
# $1 - profile
get_network_opt() {
    profile=$1
    grep profile.$profile $PROTOSTAR_TOML_FILE -A3 -m1 | sed -n 's@^.*network_opt="\(.*\)".*$@\1@p'
}

# check starknet binary presence
check_starknet() {
    which starknet &> /dev/null
    [ $? -ne 0 ] && exit_error "Unable to locate starknet binary. Did you activate your virtual env ?"
}

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
        
        contract_address=`sed -n 's@Contract address: \(.*\)@\1@p' logs.json`
        tx_hash=`sed -n 's@Transaction hash: \(.*\)@\1@p' logs.json`

        wait_for_acceptance $tx_hash

        case $? in
            0) log_success "\nTransaction accepted!"; break;;
            1) log_warning "\nTransaction rejected!"; ask "Do you want to retry";;
        esac
    done || exit_error

    echo $contract_address
}

# send a transaction that declares a contract class
# $* - command line to execute
# return The contract address
send_declare_contract_transaction() {
    transaction=$*

    while true
    do
        execute $transaction || exit_error "Error when sending transaction"
        
        contract_class_hash=`sed -n 's@Contract class hash: \(.*\)@\1@p' logs.json`
        tx_hash=`sed -n 's@Transaction hash: \(.*\)@\1@p' logs.json`

        wait_for_acceptance $tx_hash

        case $? in
            0) log_success "\nTransaction accepted!"; break;;
            1) log_warning "\nTransaction rejected!"; ask "Do you want to retry";;
        esac
    done || exit_error

    echo $contract_class_hash
}

deploy_proxified_contract() {
    path_to_implementation=$1
    implementation_class_hash=$2
    admin_address=$3

    # deploy proxy
    PROXY_ADDRESS=`send_transaction "protostar $PROFILE_OPT deploy ./build/proxy.json --inputs $implementation_class_hash"` || exit_error

    # initialize contract and set admin
    RESULT=`send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $PROXY_ADDRESS --abi $path_to_implementation --function initializer --inputs $admin_address"` || exit_error

    echo $PROXY_ADDRESS
}

upgrade_proxified_contract() {
    path_to_implementation=$1
    implementation_class_hash=$2
    proxy_address=$3

    # initialize contract and set admin
    RESULT=`send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $proxy_address --abi $path_to_implementation --function set_implementation --inputs $implementation_class_hash"` || exit_error
}

# Deploy all contracts and log the deployed addresses in the cache file
deploy_all_contracts() {
    [ -f $CACHE_FILE ] && {
        . $CACHE_FILE
        log_info "Found those deployed accounts:"
        cat $CACHE_FILE
        ask "Do you want to deploy missing contracts and initialize them" || return 
    }

    print Profile: $PROFILE
    print Admin account alias: $ADMIN_ACCOUNT
    print Admin account address: $ADMIN_ADDRESS
    print Network option: $NETWORK_OPT

    registerers=$(echo $REGISTERER_ACCOUNTS | tr "," "\n")
    print Registerer accounts: $registerers

    feeders=$(echo $FEEDER_ACCOUNTS | tr "," "\n")
    print Feeder accounts: $feeders

    ask "Are you OK to deploy with those parameters" || return 

    if [ -z $PROFILE_ADDRESS ]; then
        log_info "Deploying profile contract..."
        PROFILE_ADDRESS=`send_transaction "protostar $PROFILE_OPT deploy ./build/profile.json --inputs $ADMIN_ADDRESS"` || exit_error
    fi

    if [ -z $REGISTRY_ADDRESS ]; then
        log_info "Deploying registry contract..."
        REGISTRY_ADDRESS=`send_transaction "protostar $PROFILE_OPT deploy ./build/registry.json --inputs $ADMIN_ADDRESS"` || exit_error
    fi

    if [ -z $CONTRIBUTIONS_CLASS_HASH ]; then
        log_info "Declaring contributions contract class..."
        CONTRIBUTIONS_CLASS_HASH=`send_declare_contract_transaction "starknet declare $NETWORK_OPT --contract ./build/contributions.json"` || exit_error

        if [ -z $CONTRIBUTIONS_ADDRESS ]; then
            log_info "Deploying contributions proxy contract..."
            CONTRIBUTIONS_ADDRESS=`deploy_proxified_contract ./build/contributions_abi.json $CONTRIBUTIONS_CLASS_HASH $ADMIN_ADDRESS` || exit_error
        else
            log_info "Updating contributions proxy contract..."
            `upgrade_proxified_contract ./build/contributions_abi.json $CONTRIBUTIONS_CLASS_HASH $CONTRIBUTIONS_ADDRESS` || exit_error
        fi
    else
        if [ -z $CONTRIBUTIONS_ADDRESS ]; then
                log_info "Deploying contributions proxy contract..."
                CONTRIBUTIONS_ADDRESS=`deploy_proxified_contract ./build/contributions_abi.json $CONTRIBUTIONS_CLASS_HASH $ADMIN_ADDRESS` || exit_error
        fi
    fi

    (
        echo "PROFILE_ADDRESS=$PROFILE_ADDRESS"
        echo "REGISTRY_ADDRESS=$REGISTRY_ADDRESS"
        echo "CONTRIBUTIONS_ADDRESS=$CONTRIBUTIONS_ADDRESS"
        echo "CONTRIBUTIONS_CLASS_HASH=$CONTRIBUTIONS_CLASS_HASH"
    ) | tee >&2 $CACHE_FILE

    log_info "Setting profile contract inside registry"
    send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $REGISTRY_ADDRESS --abi ./build/registry_abi.json --function set_profile_contract --inputs $PROFILE_ADDRESS"

    log_info "Granting 'MINTER' role to the registry"
    send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $PROFILE_ADDRESS --abi ./build/profile_abi.json --function grant_minter_role --inputs $REGISTRY_ADDRESS"

    for registerer in $registerers
    do
        log_info "Granting 'REGISTERER' role to $registerer"
        send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $REGISTRY_ADDRESS --abi ./build/registry_abi.json --function grant_registerer_role --inputs $registerer"
    done

    for feeder in $feeders
    do
        log_info "Granting 'FEEDER' role to $feeder"
        send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $CONTRIBUTIONS_ADDRESS --abi ./build/contributions_abi.json --function grant_feeder_role --inputs $feeder"
    done

}

### ARGUMENT PARSING
while getopts a:p:h option
do
    case "${option}"
    in
        a) ADMIN_ACCOUNT=${OPTARG};;
        p) PROFILE=${OPTARG};;
        h) usage; exit_success;;
        \?) usage; exit_error;;
    esac
done

STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

[ -z "$ADMIN_ACCOUNT" ] && exit_error "Admin account is mandatory (use -a option) and must be set to the alias of the admin account"

[ -z "$PROFILE" ] && exit_error "Profile is mandatory (use -p option)"

CACHE_FILE="${CACHE_FILE_BASE}_$PROFILE.txt"
source "./scripts/.env.$PROFILE"

ADMIN_ADDRESS=`get_account_address $ADMIN_ACCOUNT`
[ -z $ADMIN_ADDRESS ] && exit_error "Unable to determine account address"

NETWORK_OPT=`get_network_opt $PROFILE`
[ -z "$NETWORK_OPT" ] && exit_error "Unable to determine network option"

PROFILE_OPT="--profile $PROFILE"
ACCOUNT_OPT="--account $ADMIN_ACCOUNT"

### PRE_CONDITIONS
check_starknet

### BUSINESS LOGIC

build # Need to generate ABI and compiled contracts
deploy_all_contracts

exit_success
