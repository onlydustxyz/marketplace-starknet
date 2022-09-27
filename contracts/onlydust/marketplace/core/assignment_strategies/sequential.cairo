%lang starknet
//
// This strategy limits the number of time a contributor can take a contribution in parallel
// max_parallel_count = 1 => sequential contribution
// max_parallel_count > 1 => parallel contribution
// when not using this strategy, and if coupled with a recurring strategy, a contributor can claim all available slots
//

// 
// STRATEGY IMPLEMENTATION
//

@external
func initialize(max_parallel_count) {}

@external
func can_assign(contributor_account) {
    // check slot(contributor_account) < max_parallel_count
}

@external
func on_assigned(contributor_account) {
    // increase slot(contributor_account) 
}

@external
func can_unassign(contributor_account) {
    // check slot(contributor_account) > 0
}

@external
func on_unassigned(contributor_account) {
    // decrease slot(contributor_account)
}

@external
func can_validate(contributor_account) {
    // check slot(contributor_account) > 0
}

@external
func on_validated(contributor_account) {
    // decrease slot(contributor_account)
}
