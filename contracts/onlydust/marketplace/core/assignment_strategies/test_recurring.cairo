%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.onlydust.marketplace.core.assignment_strategies.recurring import (
    initialize,
    assert_can_assign,
    on_assigned,
    assert_can_unassign,
    on_unassigned,
    assert_can_validate,
    on_validated,
    available_slot_count,
    max_slot_count,
    set_max_slot_count,
    AccessControlViewer,
)

//
// Constants
//
const CONTRIBUTOR_ACCOUNT_ADDRESS = 0x0735dc2018913023a5aa557b6b49013675ac4a35ce524cad94f5202d285678cd;
const PROJECT_CONTRACT_ADDRESS = 0x00327ae4393d1f2c6cf6dae0b533efa5d58621f9ea682f07ab48540b222fd02e;

//
// Tests
//
@external
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    AccessControlViewer.initialize(PROJECT_CONTRACT_ADDRESS);
    return ();
}

@external
func test_can_assign_if_enough_slot_left{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);
    Contribution.assign(CONTRIBUTOR_ACCOUNT_ADDRESS);

    %{
        expect_events(
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringMaxSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 0}}
        )
    %}

    return ();
}

@external
func test_cannot_assign_if_no_slot_left{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);
    Contribution.assign(CONTRIBUTOR_ACCOUNT_ADDRESS);

    %{ expect_revert(error_message='Recurring: No more slot') %}
    Contribution.assign(CONTRIBUTOR_ACCOUNT_ADDRESS);

    return ();
}

@external
func test_cannot_intialize_with_negative_slot_count{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    %{ expect_revert(error_message='Recurring: invalid slot count') %}
    initialize(-32);

    return ();
}

@external
func test_release_a_slot_when_unassigning{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);
    Contribution.assign(CONTRIBUTOR_ACCOUNT_ADDRESS);
    Contribution.unassign(CONTRIBUTOR_ACCOUNT_ADDRESS);

    %{
        expect_events(
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringMaxSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 0}},
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 1}}
        )
    %}

    return ();
}

@external
func test_cannot_release_slot_when_at_max{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);

    %{ expect_revert(error_message='Recurring: max slot count reached') %}
    Contribution.unassign(CONTRIBUTOR_ACCOUNT_ADDRESS);

    return ();
}

@external
func test_can_modify_max_slot_count{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);
    Contribution.assign(CONTRIBUTOR_ACCOUNT_ADDRESS);

    assert_that.available_slot_count_is(0);
    assert_that.max_slot_count_is(1);

    %{ stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]) %}
    set_max_slot_count(2);
    %{ stop_mock() %}

    assert_that.available_slot_count_is(1);
    assert_that.max_slot_count_is(2);

    %{
        expect_events(
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringMaxSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 0}},
           {"name": "ContributionAssignmentRecurringAvailableSlotCountChanged", "data": {"new_slot_count": 1}},
           {"name": "ContributionAssignmentRecurringMaxSlotCountChanged", "data": {"new_slot_count": 2}}
        )
    %}

    return ();
}

@external
func test_cannot_remove_assigned_slots{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);
    Contribution.assign(CONTRIBUTOR_ACCOUNT_ADDRESS);
    %{
        stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True])
        expect_revert(error_message='Recurring: invalid slot count')
    %}
    set_max_slot_count(0);
    %{ stop_mock() %}

    return ();
}

@external
func test_only_project_lead_can_modify_max_slot_count{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(1);

    %{
        stop_mock = mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [False])
        expect_revert(error_message='AccessControl: Not Project Lead')
    %}
    set_max_slot_count(2);
    %{ stop_mock() %}

    return ();
}

namespace Contribution {
    func assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account_address: felt
    ) {
        assert_can_assign(contributor_account_address);
        on_assigned(contributor_account_address);
        return ();
    }

    func unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account_address: felt
    ) {
        assert_can_unassign(contributor_account_address);
        on_unassigned(contributor_account_address);
        return ();
    }
}

namespace assert_that {
    func available_slot_count_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        expected_slot_count: felt
    ) {
        with_attr error_message("Invalid available slot_count") {
            let (slot_count) = available_slot_count();
            assert expected_slot_count = slot_count;
        }
        return ();
    }

    func max_slot_count_is{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        expected_slot_count: felt
    ) {
        with_attr error_message("Invalid max slot_count") {
            let (slot_count) = max_slot_count();
            assert expected_slot_count = slot_count;
        }
        return ();
    }
}
