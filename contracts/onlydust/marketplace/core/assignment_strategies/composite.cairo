%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call

from onlydust.marketplace.interfaces.assignment_strategy import IAssignmentStrategy

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
    strategies_len, strategies: felt*
) {
    internal.store_strategy_loop(strategies_len, strategies);
    assignment_strategy__composite__strategy_count.write(strategies_len);

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
        strategies_len, strategies: felt*
    ) {
        if (strategies_len == 0) {
            return ();
        }

        // TODO: check strat is allowed
        // IOnlyDust.assert_hash_allowed(only_dust_contract, class_hash);

        assignment_strategy__composite__strategy_hash_by_index.write(strategies_len, [strategies]);

        return store_strategy_loop(strategies_len - 1, strategies + 1);
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
