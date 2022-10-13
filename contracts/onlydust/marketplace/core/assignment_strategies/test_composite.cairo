%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

//
// INTERFACES
//
@contract_interface
namespace IComposite {
    func initialize(strategies_len, strategies: felt*) {
    }

    func strategies() -> (strategies_len: felt, strategies: felt*) {
    }
}

//
// TESTS
//
@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ context.composite_strategy_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/composite.cairo", config={"wait_for_acceptance": True}).class_hash %}

    return ();
}

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (local strategies) = alloc();
    assert strategies[0] = 0x1111;
    assert strategies[1] = 0x2222;
    assert strategies[2] = 0x3333;

    let composite_strategy_hash = Composite.declared();
    with composite_strategy_hash {
        Composite.initialize(3, strategies);

        let (strategies_len, strategies) = Composite.strategies();
        assert 3 = strategies_len;
        assert 0x1111 = strategies[0];
        assert 0x2222 = strategies[1];
        assert 0x3333 = strategies[2];
    }

    return ();
}

@view
func test_cannot_initialize_twice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    %{ expect_revert(error_message="Initializable: contract already initialized") %}
    let composite_strategy_hash = Composite.declared();
    with composite_strategy_hash {
        Composite.initialize(0, new ());
        Composite.initialize(0, new ());
    }

    return ();
}

//
// Composite functions
//
namespace Composite {
    func declared{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        tempvar composite_strategy_hash;
        %{ ids.composite_strategy_hash = context.composite_strategy_hash %}
        return composite_strategy_hash;
    }

    func initialize{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, composite_strategy_hash
    }(strategies_len, strategies: felt*) {
        IComposite.library_call_initialize(composite_strategy_hash, strategies_len, strategies);
        return ();
    }

    func strategies{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, composite_strategy_hash
    }() -> (strategies_len: felt, strategies: felt*) {
        let (strategies_len, strategies: felt*) = IComposite.library_call_strategies(
            composite_strategy_hash
        );
        return (strategies_len, strategies);
    }
}
