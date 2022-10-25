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
    AccessControlViewer,
)

const PROJECT_CONTRACT_ADDRESS = 0x00327ae4393d1f2c6cf6dae0b533efa5d58621f9ea682f07ab48540b222fd02e;
const ORACLE_CONTRACT_ADDRESS = 0x00327ae4393d1f2c6cf6dae0b533efa5d58621f9ea682f07ab48540b222fd02e;
const ADDRESS_OF_SELF = 0x0;
const ADDRESS_OF_OTHER = 0x1;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AccessControlViewer.initialize(PROJECT_CONTRACT_ADDRESS);
    return ();
}

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(ORACLE_CONTRACT_ADDRESS, 3);

    let (res) = oracle_contract_address();
    assert ORACLE_CONTRACT_ADDRESS = res;

    let (res) = contributions_count_required();
    assert 3 = res;

    return ();
}

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(ORACLE_CONTRACT_ADDRESS, 3);

    // When equal
    %{ stop_mock = mock_call(ids.ORACLE_CONTRACT_ADDRESS, "past_contribution_count", [3]) %}
    assert_can_assign(ADDRESS_OF_SELF);
    assert_can_assign(ADDRESS_OF_OTHER);
    %{ stop_mock() %}

    // When greater
    %{ stop_mock = mock_call(ids.ORACLE_CONTRACT_ADDRESS, "past_contribution_count", [4]) %}
    assert_can_assign(ADDRESS_OF_SELF);
    assert_can_assign(ADDRESS_OF_OTHER);
    %{ stop_mock() %}

    return ();
}

@view
func test_cannot_assign_when_less{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    initialize(ORACLE_CONTRACT_ADDRESS, 3);
    %{
        stop_mock = mock_call(ids.ORACLE_CONTRACT_ADDRESS, "past_contribution_count", [2])
        expect_revert(error_message="Gated: No enough contributions done.")
    %}
    assert_can_assign(ADDRESS_OF_SELF);

    return ();
}

@view
func test_change_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(ORACLE_CONTRACT_ADDRESS, 2);
    let (required) = contributions_count_required();
    assert 2 = required;

    %{ stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]) %}
    change_gate(5);
    let (required) = contributions_count_required();
    assert 5 = required;

    change_gate(1);
    let (required) = contributions_count_required();
    assert 1 = required;
    %{ stop_mock() %}

    // Still working
    %{ stop_mock = mock_call(ids.ORACLE_CONTRACT_ADDRESS, "past_contribution_count", [2]) %}
    assert_can_assign(ADDRESS_OF_SELF);
    assert_can_assign(ADDRESS_OF_OTHER);
    %{ stop_mock() %}

    return ();
}

@view
func test_change_gate_is_restricted{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(ORACLE_CONTRACT_ADDRESS, 2);

    %{
        stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False]) 
        expect_revert(error_message="AccessControl: Not Project Lead")
    %}
    change_gate(5);
    %{ stop_mock() %}

    return ();
}

@view
func test_everything_else_does_not_revert{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(ORACLE_CONTRACT_ADDRESS, 2);

    assert_can_unassign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_OTHER);
    assert_can_validate(ADDRESS_OF_SELF);
    assert_can_validate(ADDRESS_OF_OTHER);

    return ();
}
