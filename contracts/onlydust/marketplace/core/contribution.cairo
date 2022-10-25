%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import library_call, get_caller_address
from onlydust.marketplace.interfaces.assignment_strategy import IAssignmentStrategy
from onlydust.marketplace.library.access_control_viewer import AccessControlViewer
from onlydust.marketplace.constants.selectors import INITIALIZE as INITIALIZE_SELECTOR

//
// EVENTS
//
@event
func ContributionAssignmentStrategyInitialized(assignment_strategy_class_hash: felt) {
}

@event
func ContributionAssigned(contributor_account: felt) {
}

@event
func ContributionUnassigned(contributor_account: felt) {
}

@event
func ContributionValidated(contributor_account: felt) {
}

//
// STORAGE
//
@storage_var
func contribution__assignment_strategy_class_hash() -> (assignment_strategy_class_hash: felt) {
}

//
// IContribution implementation
//

@external
func assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(contributor_account) {
    let (assignment_strategy_class_hash) = contribution__assignment_strategy_class_hash.read();

    IAssignmentStrategy.library_call_assert_can_assign(
        assignment_strategy_class_hash, contributor_account
    );

    ContributionAssigned.emit(contributor_account);

    IAssignmentStrategy.library_call_on_assigned(
        assignment_strategy_class_hash, contributor_account
    );

    return ();
}

@external
func unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (assignment_strategy_class_hash) = contribution__assignment_strategy_class_hash.read();

    IAssignmentStrategy.library_call_assert_can_unassign(
        assignment_strategy_class_hash, contributor_account
    );

    ContributionUnassigned.emit(contributor_account);

    IAssignmentStrategy.library_call_on_unassigned(
        assignment_strategy_class_hash, contributor_account
    );

    return ();
}

@external
func validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (assignment_strategy_class_hash) = contribution__assignment_strategy_class_hash.read();

    IAssignmentStrategy.library_call_assert_can_validate(
        assignment_strategy_class_hash, contributor_account
    );

    ContributionValidated.emit(contributor_account);

    IAssignmentStrategy.library_call_on_validated(
        assignment_strategy_class_hash, contributor_account
    );

    return ();
}

//
// Utils
//
namespace Contribution {
    func initialize_strategy{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class_hash, calldata_len, calldata: felt*
    ) {
        library_call(class_hash, INITIALIZE_SELECTOR, calldata_len, calldata);
        contribution__assignment_strategy_class_hash.write(class_hash);
        ContributionAssignmentStrategyInitialized.emit(class_hash);

        return ();
    }

    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        let (project_contract_address) = get_caller_address();
        AccessControlViewer.initialize(project_contract_address);

        return ();
    }
}
