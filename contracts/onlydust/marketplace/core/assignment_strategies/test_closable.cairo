%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.closable import (
    assert_can_assign,
    assert_can_unassign,
    assert_can_validate,
    reopen,
    close,
    is_closed,
    AccessControlViewer,
)

const PROJECT_CONTRACT_ADDRESS = 0x00327ae4393d1f2c6cf6dae0b533efa5d58621f9ea682f07ab48540b222fd02e;
const ADDRESS_OF_SELF = 0x0;
const ADDRESS_OF_OTHER = 0x1;

@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AccessControlViewer.initialize(PROJECT_CONTRACT_ADDRESS);
    return ();
}

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Open by default
    assert_can_assign(ADDRESS_OF_SELF);
    let (closed) = is_closed();
    assert FALSE = closed;

    %{ stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]) %}
    close();
    %{ stop_mock() %}

    // Revert when closed
    %{ expect_revert(error_message="Closable: Contribution is closed") %}
    assert_can_assign(ADDRESS_OF_SELF);

    return ();
}

@view
func test_can_be_reopened{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assert_can_assign(ADDRESS_OF_SELF);
    let (closed) = is_closed();
    assert FALSE = closed;

    %{ stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]) %}
    close();
    %{ stop_mock() %}
    let (closed) = is_closed();
    assert TRUE = closed;

    %{ stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]) %}
    reopen();
    %{ stop_mock() %}
    assert_can_assign(ADDRESS_OF_SELF);
    let (closed) = is_closed();
    assert FALSE = closed;

    return ();
}

@view
func test_everything_else_does_not_revert{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_can_unassign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_OTHER);
    assert_can_validate(ADDRESS_OF_SELF);
    assert_can_validate(ADDRESS_OF_OTHER);

    %{ stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]) %}
    close();
    %{ stop_mock() %}

    assert_can_unassign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_OTHER);
    assert_can_validate(ADDRESS_OF_SELF);
    assert_can_validate(ADDRESS_OF_OTHER);

    return ();
}

@view
func test_close_is_restricted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="AccessControl: Not Project Lead") %}
    close();

    return ();
}

@view
func test_reopen_is_restricted{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{ expect_revert(error_message="AccessControl: Not Project Lead") %}
    reopen();

    return ();
}
