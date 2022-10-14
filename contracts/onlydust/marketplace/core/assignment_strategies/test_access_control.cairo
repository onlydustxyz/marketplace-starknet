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

const PROJECT_CONTRACT_ADDRESS = 0x00327ae4393d1f2c6cf6dae0b533efa5d58621f9ea682f07ab48540b222fd02e;
const ADDRESS_OF_SELF = 0x0;
const ADDRESS_OF_OTHER = 0x1;

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    initialize(PROJECT_CONTRACT_ADDRESS);

    let (res) = project_contract_address();
    assert PROJECT_CONTRACT_ADDRESS = res;

    return ();
}

// Lead Contributor

@view
func test_is_lead_contributor_true_can_do_anything{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
    %}

    assert_can_assign(ADDRESS_OF_SELF);
    assert_can_assign(ADDRESS_OF_OTHER);
    assert_can_unassign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_OTHER);
    assert_can_validate(ADDRESS_OF_SELF);
    assert_can_validate(ADDRESS_OF_OTHER);

    %{ stop_mock_lead() %}
    %{ stop_mock_member() %}

    return ();
}

// Member

@view
func test_is_member_true_can_self_assign_and_self_unassign{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [True])
    %}

    assert_can_assign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_SELF);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [True])
        expect_revert(error_message="AccessControl: Must be ProjectLead to assign another account")
    %}
    assert_can_assign(ADDRESS_OF_OTHER);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [True])
        expect_revert(error_message="AccessControl: Must be ProjectLead to unassign another account")
    %}
    assert_can_unassign(ADDRESS_OF_OTHER);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [True])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(ADDRESS_OF_SELF);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [True])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(ADDRESS_OF_OTHER);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
        expect_revert(error_message="AccessControl: Must be ProjectMember to claim a contribution")
    %}
    assert_can_assign(ADDRESS_OF_SELF);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
        expect_revert(error_message="AccessControl: Must be ProjectLead to assign another account")
    %}
    assert_can_assign(ADDRESS_OF_OTHER);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
    %}

    assert_can_unassign(ADDRESS_OF_SELF);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
        expect_revert(error_message="AccessControl: Must be ProjectLead to unassign another account")
    %}
    assert_can_unassign(ADDRESS_OF_OTHER);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(ADDRESS_OF_SELF);

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
    initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mock_lead = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        stop_mock_member = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False])
        expect_revert(error_message="AccessControl: Must be ProjectLead to validate")
    %}
    assert_can_validate(ADDRESS_OF_OTHER);

    %{
        stop_mock_lead()
        stop_mock_member()
    %}

    return ();
}
