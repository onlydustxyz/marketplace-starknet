%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import library_call, get_caller_address
from onlydust.marketplace.interfaces.assignment_strategy import IAssignmentStrategy

//
// EVENTS
//
@event
func ContributionInitialized(assignment_strategy_class_hash: felt) {
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

@storage_var
func contribution__initialized() -> (initialized: felt) {
}

//
// Common functions to be imported to any contribution implementation to be usable by OnlyDust platform
//

@external
func initialize_from_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    class_hash, calldata_len, calldata: felt*
) {
    with_attr error_message("Contribution already initialized") {
        let (initialized) = contribution__initialized.read();
        assert FALSE = initialized;
    }

    const INITIALIZE_SELECTOR = 0x79dc0da7c54b95f10aa182ad0a46400db63156920adb65eca2654c0945a463;  // initialize()
    library_call(class_hash, INITIALIZE_SELECTOR, calldata_len, calldata);

    return ();
}

@external
func set_initialized{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    assignment_strategy_class_hash: felt
) {
    contribution__initialized.write(TRUE);
    contribution__assignment_strategy_class_hash.write(assignment_strategy_class_hash);
    ContributionInitialized.emit(assignment_strategy_class_hash);
    return ();
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
