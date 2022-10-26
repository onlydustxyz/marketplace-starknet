#!/bin/bash

### TOOLS
SCRIPT_DIR=`readlink -f $0 | xargs dirname`
. $SCRIPT_DIR/tools.sh 

### FUNCTIONS
function compile() {
	FILE_PATH=$1
	NAME=`basename $FILE_PATH .cairo`

	execute starknet-compile \
		--cairo_path ./lib/cairo_contracts/src:./contracts \
		--out ./build/${NAME}.json \
		--abi ./build/${NAME}_abi.json \
		$FILE_PATH
}

### MAIN
log_info "Compiling contracts"
compile ./contracts/onlydust/marketplace/core/contribution.cairo
compile ./contracts/onlydust/marketplace/core/assignment_strategies/protection.cairo
compile ./contracts/onlydust/marketplace/core/assignment_strategies/hack_me.cairo
compile ./contracts/onlydust/marketplace/core/assignment_strategies/composite.cairo

exit_success
