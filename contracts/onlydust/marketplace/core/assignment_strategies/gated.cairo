%lang starknet

//
// This strategy checks that the contributor is eligibible to a contribution
//

// 
// EVENTS
//

@event
func ContributionGateChanged(contribution_account: felt, gate: felt) {
}

// 
// STRATEGY IMPLEMENTATION
//

@external
func initialize(past_contributions_count_required) {
    change_gate(past_contributions_count_required);
    return ();
}

@external
func can_assign(contributor_account) {
    // check past_contributions_count(contributor_account) >= past_contributions_count_required
}

@external
func on_validated() {
    // increase past_contributions_count(contributor_account)
}

// 
// MANAGEMENT FUNCTIONS
//

@external
func change_gate(new_past_contributions_count_required){
    ContributionGateChanged.emit(get_contract_address(), new_past_contributions_count_required);
    // set storage
}
