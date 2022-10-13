%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.gated import initialize, can_assign, oracle_contract_address, contributions_count_required, change_gate

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
    initialize(0x1234, 2);

    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x0]) %}

    let (res) = can_assign(0x0);
    assert res = FALSE;

    %{ stop_mock() %}

    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x1]) %}

    let (res) = can_assign(0x0);
    assert res = FALSE;

    %{ stop_mock() %}

    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x2]) %}

    let (res) = can_assign(0x0);
    assert res = TRUE;

    %{ stop_mock() %}

    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x3]) %}

    let (res) = can_assign(0x0);
    assert res = TRUE;

    %{ stop_mock() %}
    
    return ();
}

@view
func test_change_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234, 2);

    %{ stop_mock = mock_call(0x1234, "past_contribution_count", [0x3]) %}

    let (res) = can_assign(0x0);
    assert res = TRUE;

    change_gate(5);

    let (res) = can_assign(0x0);
    assert res = FALSE;

    change_gate(1);

    let (res) = can_assign(0x0);
    assert res = TRUE;

    %{ stop_mock() %}

    return ();
}