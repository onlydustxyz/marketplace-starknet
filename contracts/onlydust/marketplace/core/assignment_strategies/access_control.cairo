%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math_cmp import is_not_zero

from contracts.onlydust.marketplace.interfaces.access_control import IAccessControlViewer

@storage_var
func assignment_strategy__access_control__project_contract_address() -> (
    project_contract_address: felt
) {
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    calldata_len, calldata: felt*
) {
    assert 1 = calldata_len;
    let project_contract_address = calldata[0];

    assignment_strategy__access_control__project_contract_address.write(project_contract_address);

    return ();
}

//
// IAssignmentStrategy
//

@view
func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (caller_address) = get_caller_address();
    let (
        project_contract_address
    ) = assignment_strategy__access_control__project_contract_address.read();

    let is_assigning_to_other = is_not_zero(caller_address - contributor_account);

    let (is_project_lead) = IAccessControlViewer.is_lead_contributor(
        project_contract_address, caller_address
    );
    if (is_project_lead == TRUE) {
        return ();
    }

    with_attr error_message("AccessControl: Must be ProjectLead to assign another account") {
        assert caller_address = contributor_account;
    }

    let (is_member) = IAccessControlViewer.is_member(project_contract_address, caller_address);
    with_attr error_message("AccessControl: Must be ProjectMember to claim a contribution") {
        assert TRUE = is_member;
    }

    return ();
}

@view
func assert_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (caller_address) = get_caller_address();
    let (
        project_contract_address
    ) = assignment_strategy__access_control__project_contract_address.read();

    let is_unassigning_other = is_not_zero(caller_address - contributor_account);

    let (is_project_lead) = IAccessControlViewer.is_lead_contributor(
        project_contract_address, caller_address
    );
    with_attr error_message("AccessControl: Must be ProjectLead to unassign another account") {
        assert 0 = is_unassigning_other * (is_project_lead - 1);
    }

    return ();
}

@view
func assert_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (caller_address) = get_caller_address();
    let (
        project_contract_address
    ) = assignment_strategy__access_control__project_contract_address.read();

    let (is_project_lead) = IAccessControlViewer.is_lead_contributor(
        project_contract_address, caller_address
    );
    with_attr error_message("AccessControl: Must be ProjectLead to validate") {
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

//
// Managemement calls
//

@view
func project_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (project_contract_address: felt) {
    return assignment_strategy__access_control__project_contract_address.read();
}
