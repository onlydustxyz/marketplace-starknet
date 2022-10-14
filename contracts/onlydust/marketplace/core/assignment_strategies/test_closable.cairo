%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.core.assignment_strategies.closable import (
    assert_can_assign,
    assert_can_unassign,
    assert_can_validate,
    reopen,
    close,
    is_closed,
)

const ADDRESS_OF_SELF = 0x0;
const ADDRESS_OF_OTHER = 0x1;

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    // Open by default
    assert_can_assign(ADDRESS_OF_SELF);
    let (closed) = is_closed();
    assert FALSE = closed;

    close();

    // Revert when closed
    %{ expect_revert(error_message="Closable: Contribution is closed") %}
    assert_can_assign(ADDRESS_OF_SELF);

    return ();
}

@view
func test_can_be_reopened{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assert_can_assign(ADDRESS_OF_SELF);
    let (closed) = is_closed();
    assert FALSE = closed;

    close();
    let (closed) = is_closed();
    assert TRUE = closed;

    reopen();
    assert_can_assign(ADDRESS_OF_SELF);
    let (closed) = is_closed();
    assert FALSE = closed;

    return ();
}

@view
func test_everything_else_does_not_revert{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    assert_can_unassign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_OTHER);
    assert_can_validate(ADDRESS_OF_SELF);
    assert_can_validate(ADDRESS_OF_OTHER);

    close();

    assert_can_unassign(ADDRESS_OF_SELF);
    assert_can_unassign(ADDRESS_OF_OTHER);
    assert_can_validate(ADDRESS_OF_SELF);
    assert_can_validate(ADDRESS_OF_OTHER);

    return ();
}
