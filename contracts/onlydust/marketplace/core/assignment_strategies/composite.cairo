%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.security.Initializable.library import Initializable

//
// This strategy allows to use several strategies as a single one
//

// STORAGES
@storage_var
func assignment_strategy__composite__strategy_count() -> (strategy_count: felt) {
}

@storage_var
func assignment_strategy__composite__strategy_hash_by_index(index: felt) -> (strategy_hash: felt) {
}

//
// MANAGEMENT FUNCTIONS
//
@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    strategies_len, strategies: felt*
) {
    Initializable.initialize();
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
}
