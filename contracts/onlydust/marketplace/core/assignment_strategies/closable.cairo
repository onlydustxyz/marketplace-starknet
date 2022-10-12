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
func ContributionOpened() {
}

@external
func close{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assignment_strategy__closable__is_closed.write(TRUE);
    ContributionClosed.emit();
    return ();
}

@external
func open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assignment_strategy__closable__is_closed.write(FALSE);
    ContributionOpened.emit();
    return ();
}

@view
func can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    _contributor_account: felt
) -> (can_assign: felt) {
    let (is_closed) = assignment_strategy__closable__is_closed.read();

    if (is_closed == TRUE) {
        return (FALSE,);
    } else {
        return (TRUE,);
    }
}

@view
func is_closed{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    is_closed: felt
) {
    let (is_closed) = assignment_strategy__closable__is_closed.read();

    return (is_closed,);
}
