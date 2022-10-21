%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math_cmp import is_not_zero

from contracts.onlydust.marketplace.library.access_control_viewer import AccessControlViewer

//
// IAssignmentStrategy
//

@view
func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    alloc_locals;
    let (caller_address) = get_caller_address();

    let is_project_lead = AccessControlViewer.is_project_lead(caller_address);
    if (is_project_lead == TRUE) {
        return ();
    }

    with_attr error_message("AccessControl: Must be ProjectLead to assign another account") {
        assert caller_address = contributor_account;
    }

    with_attr error_message("AccessControl: Must be ProjectMember to claim a contribution") {
        let is_project_member = AccessControlViewer.is_project_member(caller_address);
        assert TRUE = is_project_member;
    }

    return ();
}

@view
func assert_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    alloc_locals;
    let (caller_address) = get_caller_address();

    let is_project_lead = AccessControlViewer.is_project_lead(caller_address);
    if (is_project_lead == TRUE) {
        return ();
    }

    with_attr error_message("AccessControl: Must be ProjectLead to unassign another account") {
        assert caller_address = contributor_account;
    }

    return ();
}

@view
func assert_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (caller_address) = get_caller_address();
    with_attr error_message("AccessControl: Must be ProjectLead to validate") {
        let is_project_lead = AccessControlViewer.is_project_lead(caller_address);
        assert TRUE = is_project_lead;
    }

    return ();
}

@external
func on_assigned(contributor_account) {
    return ();
}

@external
func on_unassigned(contributor_account) {
    return ();
}

@external
func on_validated(contributor_account) {
    return ();
}
