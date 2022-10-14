%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.gated import (
    initialize,
    assert_can_assign,
    assert_can_unassign,
    assert_can_validate,
    oracle_contract_address,
    contributions_count_required,
    change_gate,
)

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234, 3);

    let (res) = oracle_contract_address();
    assert 0x1234 = res;

    let (res) = contributions_count_required();
    assert 3 = res;

    return ();
}

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234, 3);

    // When equal
    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x3]) %}
    assert_can_assign(0x0);
    assert_can_assign(0x1);
    %{ stop_mock() %}

    // When greater
    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x4]) %}
    assert_can_assign(0x0);
    assert_can_assign(0x1);
    %{ stop_mock() %}

    return ();
}

@view
func test_cannot_assign_when_less{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    initialize(0x1234, 3);
    %{
        stop_mock = mock_call(0x1234, "past_contribution_count", [0x2])
        expect_revert(error_message="Gated: No enough contributions done.")
    %}
    assert_can_assign(0x0);

    return ();
}

@view
func test_change_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234, 2);
    let (required) = contributions_count_required();
    assert 2 = required;

    change_gate(5);
    let (required) = contributions_count_required();
    assert 5 = required;

    change_gate(1);
    let (required) = contributions_count_required();
    assert 1 = required;

    // Still working
    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x2]) %}
    assert_can_assign(0x0);
    assert_can_assign(0x1);
    %{ stop_mock() %}

    return ();
}

@view
func test_everything_else_does_not_revert{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_can_unassign(0x0);
    assert_can_unassign(0x1);
    assert_can_validate(0x0);
    assert_can_validate(0x1);

    return ();
}
