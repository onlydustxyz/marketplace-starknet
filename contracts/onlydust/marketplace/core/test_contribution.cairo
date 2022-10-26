%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from onlydust.marketplace.core.contribution import initialize, assign, unassign, validate
from onlydust.marketplace.test.libraries.assignment_strategy_mock import AssignmentStrategyMock

//
// CONSTANTS
//
const CONTRIBUTOR_ADDRESS = 0xafc7c6669888f3e8e6c935662b126b2a0ac6c12ca754861d54b4c17556;

//
// TESTS
//
@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let strategy_hash = AssignmentStrategyMock.setup();
    initialize(strategy_hash, 2, new (strategy_hash, 0));

    return ();
}

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    assert 1 = AssignmentStrategyMock.get_function_call_count('initialize');
    %{ expect_events({"name": "ContributionAssignmentStrategyInitialized", "data": {"assignment_strategy_class_hash": ids.test_strategy_hash}}) %}

    return ();
}

@view
func test_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    assign(CONTRIBUTOR_ADDRESS);

    assert 1 = AssignmentStrategyMock.get_function_call_count('assert_can_assign');
    assert 1 = AssignmentStrategyMock.get_function_call_count('on_assigned');

    %{ expect_events({"name": "ContributionAssigned", "data": {"contributor_account": ids.CONTRIBUTOR_ADDRESS}}) %}

    return ();
}

@view
func test_cannot_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    AssignmentStrategyMock.revert_on_call('assert_can_assign');

    %{ expect_revert() %}
    assign(CONTRIBUTOR_ADDRESS);

    return ();
}

@view
func test_claim{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    assign(0x0);

    assert 1 = AssignmentStrategyMock.get_function_call_count('assert_can_assign');
    assert 1 = AssignmentStrategyMock.get_function_call_count('on_assigned');

    %{ expect_events({"name": "ContributionAssigned", "data": {"contributor_account": 0}}) %}

    return ();
}

@view
func test_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    unassign(CONTRIBUTOR_ADDRESS);

    assert 1 = AssignmentStrategyMock.get_function_call_count('assert_can_unassign');
    assert 1 = AssignmentStrategyMock.get_function_call_count('on_unassigned');

    %{ expect_events({"name": "ContributionUnassigned", "data": {"contributor_account": ids.CONTRIBUTOR_ADDRESS}}) %}

    return ();
}

@view
func test_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    validate(CONTRIBUTOR_ADDRESS);

    assert 1 = AssignmentStrategyMock.get_function_call_count('assert_can_validate');
    assert 1 = AssignmentStrategyMock.get_function_call_count('on_validated');

    %{ expect_events({"name": "ContributionValidated", "data": {"contributor_account": ids.CONTRIBUTOR_ADDRESS}}) %}

    return ();
}
