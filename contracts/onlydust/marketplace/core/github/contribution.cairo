%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from openzeppelin.security.initializable.library import Initializable

from onlydust.marketplace.interfaces.project import IProject
from onlydust.marketplace.interfaces.contributor_oracle import IContributorOracle

struct Status {
    NONE: felt,
    OPEN: felt,
    ASSIGNED: felt,
    COMPLETED: felt,
    ABANDONED: felt,
}

//
// Events
//
@event
func ContributionCreated(contribution_id: felt, project_id: felt, issue_number: felt, gate: felt) {
}

@event
func ContributionDeleted(contribution_id: felt) {
}

@event
func ContributionAssigned(contribution_id: felt, contributor_id: Uint256) {
}

@event
func ContributionUnassigned(contribution_id: felt) {
}

@event
func ContributionClaimed(contribution_id: felt, contributor_id: Uint256) {
}

@event
func ContributionValidated(contribution_id: felt) {
}

@event
func ContributionGateChanged(contribution_id: felt, gate: felt) {
}

//
// Storage
//
@storage_var
func contribution_contributor_oracle_() -> (contributor_oracle: felt) {
}

@storage_var
func contribution_project_contract_() -> (project_contract: felt) {
}

@storage_var
func contribution_repo_id_() -> (repo_id: felt) {
}

@storage_var
func contribution_status_() -> (status: felt) {
}

@storage_var
func contribution_contributor_() -> (contributor_account: felt) {
}

@storage_var
func contribution_gate_() -> (gate: felt) {
}

//
// Init
//
@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_oracle: felt, project_contract: felt, repo_id: felt, issue_number: felt, gate: felt
) {
    let (initialized) = Initializable.initialized();
    assert initialized = FALSE;
    Initializable.initialize();

    let (contribution_address) = get_contract_address();
    ContributionCreated.emit(contribution_address, repo_id, issue_number, gate);

    contribution_contributor_oracle_.write(contributor_oracle);
    contribution_project_contract_.write(project_contract);
    contribution_repo_id_.write(repo_id);
    contribution_status_.write(Status.OPEN);
    contribution_gate_.write(gate);
    return ();
}

//
// IContribution implementation
//
@external
func assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account: felt
) {
    access_control.assert_can_assign(contributor_account);
    status_access.only_open();
    gating.assert_contributor_is_eligible(contributor_account);

    // Update storage
    contribution_status_.write(Status.ASSIGNED);
    contribution_contributor_.write(contributor_account);

    // Emit event
    let (contribution_address) = get_contract_address();
    ContributionAssigned.emit(contribution_address, Uint256(contributor_account, 0));

    return ();
}

@external
func unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    access_control.assert_can_unassign();
    status_access.only_assigned();

    // Update storage
    contribution_status_.write(Status.OPEN);
    contribution_contributor_.write(0);

    // Emit event
    let (contribution_address) = get_contract_address();
    ContributionUnassigned.emit(contribution_address);

    return ();
}

// !CAUTION!: in order to update past_contribution_count of the contributor, this function
// must be called through the 'contributions' contract only.
@external
func validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    access_control.assert_can_validate();
    status_access.only_assigned();

    // Update storage
    contribution_status_.write(Status.COMPLETED);

    // Emit event
    let (contribution_address) = get_contract_address();
    ContributionValidated.emit(contribution_address);

    return ();
}

namespace access_control {
    func is_lead_contributor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account: felt
    ) -> (result: felt) {
        alloc_locals;
        let (project_contract) = contribution_project_contract_.read();
        let (is_lead: felt) = IProject.is_lead_contributor(project_contract, contributor_account);
        return (result=is_lead);
    }

    func is_project_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account: felt
    ) -> (result: felt) {
        alloc_locals;
        let (project_contract) = contribution_project_contract_.read();
        let (is_member: felt) = IProject.is_member(project_contract, contributor_account);
        return (result=is_member);
    }

    func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account: felt
    ) {
        alloc_locals;
        let (caller) = get_caller_address();

        let (is_lead) = is_lead_contributor(caller);
        if (is_lead == 1) {
            return ();
        }

        let (is_member) = is_project_member(caller);
        if (is_member == 1 and contributor_account == caller) {
            return ();
        }

        with_attr error_message("Contribution: LEAD_CONTRIBUTOR or PROJECT_MEMBER role required") {
            assert 1 = 0;
        }
        return ();
    }

    func assert_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        let (caller) = get_caller_address();
        let (is_lead) = is_lead_contributor(caller);

        with_attr error_message("Contribution: LEAD_CONTRIBUTOR role required") {
            assert 1 = is_lead;
        }
        return ();
    }

    func assert_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        let (caller) = get_caller_address();
        let (is_lead) = is_lead_contributor(caller);

        with_attr error_message("Contribution: LEAD_CONTRIBUTOR role required") {
            assert 1 = is_lead;
        }
        return ();
    }
}

namespace status_access {
    func only_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        let (status) = contribution_status_.read();
        with_attr error_message("Contribution: Contribution is not OPEN") {
            assert Status.OPEN = status;
        }
        return ();
    }

    func only_assigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        alloc_locals;
        let (status) = contribution_status_.read();
        with_attr error_message("Contribution: Contribution is not ASSIGNED") {
            assert Status.ASSIGNED = status;
        }
        return ();
    }
}

namespace gating {
    func is_contributor_eligible{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account: felt
    ) -> (result: felt) {
        alloc_locals;
        let (contributor_oracle) = contribution_contributor_oracle_.read();
        let (past_contribution_count) = IContributorOracle.past_contribution_count(
            contributor_oracle, contributor_account
        );
        let (gate) = contribution_gate_.read();
        let result = is_le(gate, past_contribution_count);
        return (result=result);
    }

    func assert_contributor_is_eligible{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contributor_account: felt) {
        let (is_eligible) = is_contributor_eligible(contributor_account);
        with_attr error_message("Contribution: Contributor is not eligible") {
            assert 1 = is_eligible;
        }
        return ();
    }
}
