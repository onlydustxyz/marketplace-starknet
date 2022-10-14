%lang starknet

//
// This strategy can "close" a contribution and forbid it to be assigned ever again
// still allowing on going asssignments to complete
//

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

@storage_var
func assignment_strategy__closable__is_closed() -> (is_closed: felt) {
}

@event
func ContributionClosed() {
}

@event
func ContributionReopened() {
}

//
// IAssignmentStrategy
//

@view
func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _contributor_account: felt
) {
    let (is_closed) = assignment_strategy__closable__is_closed.read();
    with_attr error_message("Closable: Contribution is closed") {
        assert FALSE = is_closed;
    }

    return ();
}

@external
func on_assigned(contributor_account) {
    return ();
}

@view
func assert_can_unassign(contributor_account) {
    return ();
}

@external
func on_unassigned(contributor_account) {
    return ();
}

@view
func assert_can_validate(contributor_account) {
    return ();
}

@external
func on_validated(contributor_account) {
    return ();
}

//
// Managemement calls
//

@external
func close{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assignment_strategy__closable__is_closed.write(TRUE);
    ContributionClosed.emit();
    return ();
}

@external
func reopen{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assignment_strategy__closable__is_closed.write(FALSE);
    ContributionReopened.emit();
    return ();
}

@view
func is_closed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    is_closed: felt
) {
    return assignment_strategy__closable__is_closed.read();
}
