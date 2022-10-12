%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.closable import (
    can_assign,
    open,
    close,
    is_closed,
)

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Open by default
    let (res) = can_assign(0x0);
    assert TRUE = res;
    let (closed) = is_closed();
    assert FALSE = closed;

    close();

    // Can be closed
    let (res) = can_assign(0x0);
    assert FALSE = res;
    let (closed) = is_closed();
    assert TRUE = closed;

    open();

    // Can be re-opened
    let (res) = can_assign(0x0);
    assert TRUE = res;
    let (closed) = is_closed();
    assert FALSE = closed;

    return ();
}
