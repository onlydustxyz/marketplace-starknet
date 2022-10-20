%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call

//
// This strategy allows to use several strategies as a single one
//

// Example of contribution creation with composite strategies

// Gated (past_contributions_count_required = 3)
// Sequential (max_parallel_count = 1)
// Recurring (slot_count = 30)

// starknet invoke --abi project.json --contract_address $project_contract --function new_contribution --inputs \
//     $github_contribution_hash $composite_hash 12 \
//     $access_control_hash 1 $project_contract \
//     $gated_hash 1 3 \
//     $sequential_hash 1 1 \
//     $recurring_hash 1 30 \

// STORAGES
@storage_var
func assignment_strategy__composite__initialized() -> (initialized: felt) {
}

@storage_var
func assignment_strategy__composite__strategy_count() -> (strategy_count: felt) {
}

@storage_var
func assignment_strategy__composite__strategy_hash_by_index(index: felt) -> (strategy_hash: felt) {
}

//
// STRATEGY IMPLEMENTATION
//

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) -> (retdata_size: felt, retdata: felt*) {
    let (all_strategies_len, all_strategies) = strategies();
    internal.loop(all_strategies_len, all_strategies, selector, calldata_size, calldata);
    return (retdata_size=0, retdata=new ());
}

//
// MANAGEMENT FUNCTIONS
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    calldata_len, calldata: felt*
) {
    with_attr error_message("Composite: already initialized") {
        let (initialized) = assignment_strategy__composite__initialized.read();
        assert FALSE = initialized;
        assignment_strategy__composite__initialized.write(TRUE);
    }

    let strategies_count = internal.store_strategy_loop(calldata_len, calldata);
    assignment_strategy__composite__strategy_count.write(strategies_count);

    return ();
}

@view
func strategies{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    strategies_len: felt, strategies: felt*
) {
    alloc_locals;

    let (strategies_len) = assignment_strategy__composite__strategy_count.read();
    let (local strategies) = alloc();
    internal.read_strategy_loop(strategies_len, strategies);

    return (strategies_len, strategies);
}

//
// INTERNAL
//
namespace internal {
    func store_strategy_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        calldata_len, calldata: felt*
    ) -> felt {
        if (calldata_len == 0) {
            return (0);
        }

        let strategy_hash = calldata[0];
        let strategy_calldata_len = calldata[1];

        let next_calldata_len = calldata_len - (strategy_calldata_len + 2);
        let next_calldata = calldata + strategy_calldata_len + 2;
        let count = internal.store_strategy_loop(next_calldata_len, next_calldata);

        // TODO: check strat is allowd
        // IOnlyDust.assert_hash_allowed(only_dust_contract, class_hash);

        const INITIALIZE_SELECTOR = 0x79dc0da7c54b95f10aa182ad0a46400db63156920adb65eca2654c0945a463;  // initialize()
        library_call(strategy_hash, INITIALIZE_SELECTOR, strategy_calldata_len, calldata + 2);
        assignment_strategy__composite__strategy_hash_by_index.write(1 + count, strategy_hash);

        return 1 + count;
    }

    func read_strategy_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        strategies_len, strategies: felt*
    ) {
        if (strategies_len == 0) {
            return ();
        }

        let (strategy) = assignment_strategy__composite__strategy_hash_by_index.read(
            strategies_len
        );
        assert [strategies] = strategy;

        return read_strategy_loop(strategies_len - 1, strategies + 1);
    }

    func loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        all_strategies_len, all_strategies: felt*, selector, calldata_size, calldata: felt*
    ) {
        if (all_strategies_len == 0) {
            return ();
        }

        library_call(
            class_hash=[all_strategies],
            function_selector=selector,
            calldata_size=calldata_size,
            calldata=calldata,
        );

        return loop(all_strategies_len - 1, all_strategies + 1, selector, calldata_size, calldata);
    }
}
