%lang starknet
//
// This strategy limit the number of assignments per contributor
// slot_count = 0 => strategy is locked, no assignment possible unless we add more slots
// slot_count = 1 => normal contribution
// slot count > 1 => recurring contribution
// not using this strategy means infinite contribution
//

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.math import assert_not_zero, assert_nn, assert_le
from starkware.starknet.common.syscalls import get_tx_info
from onlydust.marketplace.library.access_control_viewer import AccessControlViewer

//
// Events
//
@event
func ContributionAssignmentRecurringAvailableSlotsUpdated(new_slot_count) {
}

@event
func ContributionAssignmentRecurringMaxSlotsUpdated(new_slot_count) {
}

//
// Storage
//
@storage_var
func assignment_strategy__recurring__available_slot_count() -> (slot_count: felt) {
}

@storage_var
func assignment_strategy__recurring__max_slot_count() -> (slot_count: felt) {
}

//
// STRATEGY IMPLEMENTATION
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    max_slot_count: felt
) {
    internal.set_max_slot_count(max_slot_count);
    return ();
}

@external
func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    with_attr error_message("Recurring: No more slot") {
        let slot_count = internal.available_slot_count();
        assert_not_zero(slot_count);
    }
    return ();
}

@external
func on_assigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    let slot_count = internal.available_slot_count();
    internal.set_available_slot_count(slot_count - 1);
    return ();
}

@external
func assert_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    alloc_locals;

    with_attr error_message("Recurring: max slot count reached") {
        let slot_count = internal.available_slot_count();
        let max_slot_count = internal.max_slot_count();
        assert_le(slot_count + 1, max_slot_count);
    }
    return ();
}

@external
func on_unassigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    let slot_count = internal.available_slot_count();
    internal.set_available_slot_count(slot_count + 1);
    return ();
}

@external
func assert_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

@external
func on_validated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

//
// Management functions
//
@view
func available_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    slot_count: felt
) {
    let slot_count = internal.available_slot_count();
    return (slot_count,);
}

@view
func max_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    slot_count: felt
) {
    let slot_count = internal.max_slot_count();
    return (slot_count,);
}

@external
func set_max_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_max_slot_count: felt
) {
    AccessControlViewer.assert_account_caller_is_project_lead();
    internal.set_max_slot_count(new_max_slot_count);
    return ();
}

//
// Internal functions
//
namespace internal {
    func available_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> felt {
        let (slot_count) = assignment_strategy__recurring__available_slot_count.read();
        return slot_count;
    }

    func set_available_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_slot_count
    ) {
        with_attr error_message("Recurring: invalid slot count") {
            assert_nn(new_slot_count);
        }

        assignment_strategy__recurring__available_slot_count.write(new_slot_count);
        ContributionAssignmentRecurringAvailableSlotsUpdated.emit(new_slot_count);
        return ();
    }

    func max_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        let (slot_count) = assignment_strategy__recurring__max_slot_count.read();
        return slot_count;
    }

    func set_max_slot_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        new_max_slot_count
    ) {
        alloc_locals;
        let max_slot_count = internal.max_slot_count();
        let additional_slots = new_max_slot_count - max_slot_count;

        let slot_count = internal.available_slot_count();
        internal.set_available_slot_count(slot_count + additional_slots);

        assignment_strategy__recurring__max_slot_count.write(new_max_slot_count);
        ContributionAssignmentRecurringMaxSlotsUpdated.emit(new_max_slot_count);
        return ();
    }

    func get_account_caller_address{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> felt {
        let (tx_info) = get_tx_info();
        return tx_info.account_contract_address;
    }
}
