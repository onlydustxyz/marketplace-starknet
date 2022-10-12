%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.access_control import (
    initialize,
    can_assign,
    can_unassign,
    can_validate,
    assignment_strategy_access_control_project_contract_address,
)

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234);

    let (
        project_contract_address
    ) = assignment_strategy_access_control_project_contract_address.read();
    assert 0x1234 = project_contract_address;

    return ();
}

@view
func test_is_lead_contributor_true{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    initialize(0x1234);

    %{ stop_mock = mock_call(0x1234, "is_lead_contributor", [0x1]) %}

    let (res) = can_assign(0x0);
    assert res = TRUE;
    let (res) = can_assign(0x1);
    assert res = TRUE;
    let (res) = can_unassign(0x0);
    assert res = TRUE;
    let (res) = can_unassign(0x1);
    assert res = TRUE;
    let (res) = can_validate(0x0);
    assert res = TRUE;
    let (res) = can_validate(0x1);
    assert res = TRUE;

    %{ stop_mock() %}

    return ();
}

@view
func test_is_member_true{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x1])
    %}

    let (res) = can_assign(0x0);
    assert res = TRUE;
    let (res) = can_assign(0x1);
    assert res = FALSE;

    let (res) = can_unassign(0x0);
    assert res = TRUE;
    let (res) = can_unassign(0x1);
    assert res = FALSE;

    let (res) = can_validate(0x0);
    assert res = FALSE;
    let (res) = can_validate(0x1);
    assert res = FALSE;

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_is_member_false{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
    %}

    let (res) = can_assign(0x0);
    assert res = FALSE;
    let (res) = can_assign(0x1);
    assert res = FALSE;

    let (res) = can_unassign(0x0);
    assert res = TRUE;
    let (res) = can_unassign(0x1);
    assert res = FALSE;

    let (res) = can_validate(0x0);
    assert res = FALSE;
    let (res) = can_validate(0x1);
    assert res = FALSE;

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}
