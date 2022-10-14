%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.access_control import (
    initialize,
    assert_can_assign,
    assert_can_unassign,
    assert_can_validate,
    project_contract_address,
)

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(0x1234);

    let (res) = project_contract_address();
    assert 0x1234 = res;

    return ();
}

// Lead Contributor

@view
func test_is_lead_contributor_true_can_do_anything{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x1])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
    %}

    assert_can_assign(0x0);
    assert_can_assign(0x1);
    assert_can_unassign(0x0);
    assert_can_unassign(0x1);
    assert_can_validate(0x0);
    assert_can_validate(0x1);

    %{ stop_mock_lead() %}
    %{ stop_mock_member() %}

    return ();
}

// Member

@view
func test_is_member_true_can_self_assign_and_self_unassign{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x1])
    %}

    assert_can_assign(0x0);
    assert_can_unassign(0x0);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_is_member_true_cannot_assign_other{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x1])
        expect_revert(error_message="AccessControl: Must be ProjectLead to assign another account")
    %}
    assert_can_assign(0x1);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_is_member_true_cannot_unassign_other{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x1])
        expect_revert(error_message="AccessControl: Must be ProjectLead to unassign another account")
    %}
    assert_can_unassign(0x1);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_is_member_true_cannot_validate_self{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x1])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(0x0);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_is_member_true_cannot_validate_others{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x1])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(0x1);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

// No role

@view
func test_no_role_cannot_self_assign{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
        expect_revert(error_message="AccessControl: Must be ProjectMember to claim a contribution")
    %}
    assert_can_assign(0x0);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_no_role_cannot_assign_to_other{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
        expect_revert(error_message="AccessControl: Must be ProjectLead to assign another account")
    %}
    assert_can_assign(0x1);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_no_role_can_self_unassign{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
    %}

    assert_can_unassign(0x0);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_no_role_cannot_unassign_other{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
        expect_revert(error_message="AccessControl: Must be ProjectLead to unassign another account")
    %}
    assert_can_unassign(0x1);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_no_role_cannot_self_validate{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(0x0);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}

@view
func test_no_role_cannot_validate_others{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(0x1234);

    %{
        stop_mock_lead = mock_call(0x1234, "is_lead_contributor", [0x0])
        stop_mock_member = mock_call(0x1234, "is_member", [0x0])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(0x1);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}
