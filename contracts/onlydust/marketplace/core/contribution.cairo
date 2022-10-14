%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import FALSE
from starkware.starknet.common.syscalls import library_call, get_caller_address
from onlydust.marketplace.interfaces.assignment_strategy import IAssignmentStrategy
from openzeppelin.security.Initializable.library import Initializable

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
func ContributionClaimed(contributor_account: felt) {
}

//
// STORAGE
//
@storage_var
func contribution__assignment_strategy_class_hash() -> (assignment_strategy_class_hash: felt) {
}

//
// Common functions to be imported to any contribution implementation to be usable by OnlyDust platform
//

@external
func initialize_from_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    class_hash, calldata_len, calldata: felt*
) {
    with_attr error_message("Contribution already initialized") {
        let (initialized) = Initializable.initialized();
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
    Initializable.initialize();
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

    let (caller_address) = get_caller_address();
    if (caller_address == contributor_account) {
        ContributionClaimed.emit(contributor_account);
    } else {
        ContributionAssigned.emit(contributor_account);
    }

    IAssignmentStrategy.library_call_on_assigned(
        assignment_strategy_class_hash, contributor_account
    );

    return ();
}
