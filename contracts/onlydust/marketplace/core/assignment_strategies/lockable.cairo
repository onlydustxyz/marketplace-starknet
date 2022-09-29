%lang starknet
//
// This strategy can "lock" a contribution and forbid it to be assigned ever again
// still allowing on going asssignments to complete
//

//
// STRATEGY IMPLEMENTATION
//

@external
func can_assign(contributor_account) {
    // check locked == false
}

@external
func lock() {
    // set locked == true
    ContributionDeleted.emit(get_contract_address());
    return ();
}

@external
func unlock() {
    // set locked == false
}
