#!/bin/bash

### CONSTANTS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
ROOT=`readlink -f $SCRIPT_DIR/..`
CACHE_FILE_BASE=$ROOT/scripts/configuration/deployed_contracts
STARKNET_ACCOUNTS_FILE=$HOME/.starknet_accounts/starknet_open_zeppelin_accounts.json
PROTOSTAR_TOML_FILE=$ROOT/protostar.toml
STARKNET_VERSION="0.9.1"

### FUNCTIONS
. $SCRIPT_DIR/logging.sh # Logging utilities
. $SCRIPT_DIR/tools.sh   # script utilities

# print the script usage
usage() {
    print "$0 [-a ADMIN_ACCOUNT] [-p PROFILE] [-y]"
}

# clean the protostar project
clean() {
    log_info "Cleaning..."
    rm -f ./build/*_migration{,_abi}.json
    if [ $? -ne 0 ]; then exit_error "Problem during clean"; fi
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
    grep profile.$profile $PROTOSTAR_TOML_FILE -A5 -m1 | sed -n 's@^.*network_opt = "\(.*\)".*$@\1@p'
}

# check starknet binary presence
check_starknet() {
    which starknet &> /dev/null
    [ $? -ne 0 ] && exit_error "Unable to locate starknet binary. Did you activate your virtual env ?"
    version=$(starknet -v)
    if [ "$version" != "starknet $STARKNET_VERSION" ]; then
        exit_error "Invalid starknet version: $version. Version $STARKNET_VERSION is required"
    fi
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

deploy_proxy() {
    path_to_implementation=$1
    implementation_class_hash=$2
    initializer_inputs=$3

    # deploy proxy
    PROXY_ADDRESS=`send_transaction "starknet $NETWORK_OPT deploy --no_wallet --contract ./build/proxy.json --inputs $implementation_class_hash"` || exit_error

    # initialize contract and set admin
    RESULT=`send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $PROXY_ADDRESS --abi $path_to_implementation --function initializer --inputs $initializer_inputs"` || exit_error

    echo $PROXY_ADDRESS
}

update_proxified_contract() {
    path_to_implementation=$1
    implementation_class_hash=$2
    proxy_address=$3

    # initialize contract and set admin
    RESULT=`send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $proxy_address --abi $path_to_implementation --function set_implementation --inputs $implementation_class_hash"` || exit_error
}

update_proxified_contract_with_migration() {
    path_to_implementation=$1
    implementation_class_hash=$2
    migration_class_hash=$3
    proxy_address=$4

    # initialize contract and set admin
    RESULT=`send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $proxy_address --abi $path_to_implementation --function set_implementation_with_migration --inputs $implementation_class_hash $migration_class_hash"` || exit_error
}

deploy_proxified_contract() {
    contract=$1
    proxy_address=$2
    initializer_inputs=$3

    log_info "Declaring contract class..."
    implementation_class_hash=`send_declare_contract_transaction "starknet declare $NETWORK_OPT --contract ./build/${contract}.json"` || exit_error

    if [ -z $proxy_address ]; then
        log_info "Deploying proxy contract..."
        proxy_address=`deploy_proxy ./build/${contract}_abi.json $implementation_class_hash "$initializer_inputs"` || exit_error
    else

        migration_file_path="./build/${contract}_migration.json"

        if [ -f $migration_file_path ]; then
            ask "Do you want to update the implementation of ${contract} and run the migration ${contract}_migration?"
            if [ $? -eq 0 ]; then
                log_info "Declaring migration class..."
                migration_class_hash=`send_declare_contract_transaction "starknet declare $NETWORK_OPT --contract $migration_file_path"` || exit_error

                log_info "Updating proxy contract implementation and running migration..."
                `update_proxified_contract_with_migration ./build/${contract}_abi.json $implementation_class_hash $migration_class_hash $proxy_address` || exit_error
            else
                ask "Do you want to update the implementation of ${contract}?"
                if [ $? -eq 0 ]; then
                    log_info "Updating proxy contract implementation..."
                    `update_proxified_contract ./build/${contract}_abi.json $implementation_class_hash $proxy_address` || exit_error
                fi
            fi
        else
            ask "Do you want to update the implementation of ${contract}?"
            if [ $? -eq 0 ]; then
                log_info "Updating proxy contract implementation..."
                `update_proxified_contract ./build/${contract}_abi.json $implementation_class_hash $proxy_address` || exit_error
            fi
        fi
    fi

    echo $proxy_address
}

# Deploy all contracts and log the deployed addresses in the cache file
deploy_all_contracts() {
    [ -f $CACHE_FILE ] && {
        . $CACHE_FILE
        log_info "Found those deployed accounts:"
        cat $CACHE_FILE
        ask "\nDo you want to deploy missing contracts and initialize them" || return 
    }

    print Profile: $PROFILE
    print Admin account alias: $ADMIN_ACCOUNT
    print Admin account address: $ADMIN_ADDRESS
    print Network option: $NETWORK_OPT

    registerers=$(echo $REGISTERER_ACCOUNTS | tr "," "\n")
    print Registerer accounts: $registerers

    ask "Are you OK to deploy with those parameters" || return 

    if [ -z $PROFILE_ADDRESS ]; then
        log_info "Deploying profile contract..."
        PROFILE_ADDRESS=`send_transaction "starknet $NETWORK_OPT deploy --no_wallet --contract ./build/profile.json --inputs $ADMIN_ADDRESS"` || exit_error
    fi

    if [ -z $REGISTRY_ADDRESS ]; then
        log_info "Deploying registry contract..."
        REGISTRY_ADDRESS=`send_transaction "starknet $NETWORK_OPT deploy --no_wallet --contract ./build/registry.json --inputs $ADMIN_ADDRESS"` || exit_error
    fi

    CONTRIBUTIONS_ADDRESS=`deploy_proxified_contract "contributions" "$CONTRIBUTIONS_ADDRESS" "$ADMIN_ADDRESS $REGISTRY_ADDRESS"` || exit_error

    (
        echo "PROFILE_ADDRESS=$PROFILE_ADDRESS"
        echo "REGISTRY_ADDRESS=$REGISTRY_ADDRESS"
        echo "CONTRIBUTIONS_ADDRESS=$CONTRIBUTIONS_ADDRESS"
    ) | tee >&2 $CACHE_FILE

    ask "Do you want to setup the contracts (for a first deployment)" || return 

    log_info "Setting profile contract inside registry"
    send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $REGISTRY_ADDRESS --abi ./build/registry_abi.json --function set_profile_contract --inputs $PROFILE_ADDRESS"

    log_info "Setting registry contract inside contributions"
    send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $CONTRIBUTIONS_ADDRESS --abi ./build/contributions_abi.json --function set_registry_contract_address --inputs $REGISTRY_ADDRESS"

    log_info "Granting 'MINTER' role to the registry"
    send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $PROFILE_ADDRESS --abi ./build/profile_abi.json --function grant_minter_role --inputs $REGISTRY_ADDRESS"

    for registerer in $registerers
    do
        log_info "Granting 'REGISTERER' role to $registerer"
        send_transaction "starknet invoke $ACCOUNT_OPT $NETWORK_OPT --address $REGISTRY_ADDRESS --abi ./build/registry_abi.json --function grant_registerer_role --inputs $registerer"
    done
}

### ARGUMENT PARSING
while getopts a:p:yh option
do
    case "${option}"
    in
        a) ADMIN_ACCOUNT=${OPTARG};;
        p) PROFILE=${OPTARG};;
        y) AUTO_YES="true";;
        h) usage; exit_success;;
        \?) usage; exit_error;;
    esac
done

export STARKNET_WALLET=starkware.starknet.wallets.open_zeppelin.OpenZeppelinAccount

[ -z "$ADMIN_ACCOUNT" ] && exit_error "Admin account is mandatory (use -a option) and must be set to the alias of the admin account"

[ -z "$PROFILE" ] && exit_error "Profile is mandatory (use -p option)"

CACHE_FILE="${CACHE_FILE_BASE}_$PROFILE.txt"
source "./scripts/configuration/.env.$PROFILE"

ADMIN_ADDRESS=`get_account_address $ADMIN_ACCOUNT`
[ -z $ADMIN_ADDRESS ] && exit_error "Unable to determine account address"

NETWORK_OPT=`get_network_opt $PROFILE`
[ -z "$NETWORK_OPT" ] && exit_error "Unable to determine network option"

PROFILE_OPT="--profile $PROFILE"
ACCOUNT_OPT="--account $ADMIN_ACCOUNT"

### PRE_CONDITIONS
check_starknet

### BUSINESS LOGIC

clean # Need to remove ABI and compiled contracts that may not exist anymore (eg. migrations)
build # Need to generate ABI and compiled contracts
deploy_all_contracts

exit_success
