%lang starknet
//
// This strategy limit the number of assignments per contributor
// slot_count = 0 => strategy is locked, no assignment possible unless we add more slots
// slot_count = 1 => normal contribution
// slot count > 1 => recurring contribution
// not using this strategy means infinite contribution
//

from starkware.cairo.common.cairo_builtins import HashBuiltin

//
// Events
//

//
// STRATEGY IMPLEMENTATION
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    max_slot_count: felt
) {
    return ();
}

@external
func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

@external
func on_assigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

@external
func assert_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

@external
func on_unassigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

@external
func assert_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}

@external
func on_validated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account_address: felt
) {
    return ();
}
