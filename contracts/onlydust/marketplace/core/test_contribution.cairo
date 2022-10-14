%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from onlydust.marketplace.core.contribution import initialize_from_hash
from onlydust.marketplace.test.libraries.assignment_strategy_mock import AssignmentStrategyMock

@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AssignmentStrategyMock.setup();
    return ();
}

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();
    initialize_from_hash(test_strategy_hash, 0, new ());
    initialize_from_hash(test_strategy_hash, 0, new ());

    assert 2 = AssignmentStrategyMock.get_function_call_count('initialize');
    return ();
}
