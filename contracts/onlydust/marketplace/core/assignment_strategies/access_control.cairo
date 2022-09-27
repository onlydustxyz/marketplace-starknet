%lang starknet

//
// This strategy check that the caller address is allowed to perform the requested actions
//

//
// STRATEGY IMPLEMENTATION
//

@external
func initialize(project_contract) {}

@external
func can_assign(contributor_account) {
    // check project_contract.is_lead_contributor(get_caller_address()) or 
    // project_contract.is_member(contributor_account) and get_caller_address() == contributor_account
}

@external
func can_unassign(contributor_account) {
    // check project_contract.is_lead_contributor(get_caller_address()) or 
    // project_contract.is_member(contributor_account) and get_caller_address() == contributor_account
}

@external
func can_validate(contributor_account) {
    // check project_contract.is_lead_contributor(get_caller_address()) 
}
