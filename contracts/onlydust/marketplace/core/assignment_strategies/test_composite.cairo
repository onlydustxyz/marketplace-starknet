%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from onlydust.marketplace.interfaces.assignment_strategy import IAssignmentStrategy
from onlydust.marketplace.test.libraries.assignment_strategy_mock import AssignmentStrategyMock

//
// CONSTANTS
//
const CONTRIBUTOR_ADDRESS = 0x069642afc7c6669888f3e8e6c935662b126b2a0ac6c12ca754861d54b4c17556;

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
    AssignmentStrategyMock.setup();
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
    %{ expect_revert(error_message="Composite: already initialized") %}
    let composite_strategy_hash = Composite.declared();
    with composite_strategy_hash {
        Composite.initialize(0, new ());
        Composite.initialize(0, new ());
    }

    return ();
}

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_assert_can_assign(
        composite_strategy_hash, CONTRIBUTOR_ADDRESS
    );

    assert 3 = AssignmentStrategyMock.get_function_call_count('assert_can_assign');

    return ();
}

@view
func test_cannot_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AssignmentStrategyMock.revert_on_call('assert_can_assign');

    %{ expect_revert() %}
    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.assert_can_assign(composite_strategy_hash, CONTRIBUTOR_ADDRESS);

    return ();
}

@view
func test_on_assigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_on_assigned(composite_strategy_hash, CONTRIBUTOR_ADDRESS);

    assert 3 = AssignmentStrategyMock.get_function_call_count('on_assigned');

    return ();
}

@view
func test_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_assert_can_unassign(
        composite_strategy_hash, CONTRIBUTOR_ADDRESS
    );

    assert 3 = AssignmentStrategyMock.get_function_call_count('assert_can_unassign');

    return ();
}

@view
func test_on_unassigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_on_unassigned(composite_strategy_hash, CONTRIBUTOR_ADDRESS);

    assert 3 = AssignmentStrategyMock.get_function_call_count('on_unassigned');

    return ();
}

@view
func test_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_assert_can_validate(
        composite_strategy_hash, CONTRIBUTOR_ADDRESS
    );

    assert 3 = AssignmentStrategyMock.get_function_call_count('assert_can_validate');

    return ();
}

@view
func test_on_validated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_on_validated(composite_strategy_hash, CONTRIBUTOR_ADDRESS);

    assert 3 = AssignmentStrategyMock.get_function_call_count('on_validated');

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

    func default{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;

        let test_strategy_hash = AssignmentStrategyMock.class_hash();
        let (local strategies) = alloc();
        assert strategies[0] = test_strategy_hash;
        assert strategies[1] = test_strategy_hash;
        assert strategies[2] = test_strategy_hash;

        let composite_strategy_hash = declared();
        with composite_strategy_hash {
            initialize(3, strategies);
        }

        return composite_strategy_hash;
    }
}
