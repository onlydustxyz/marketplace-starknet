%lang starknet

//
// Common functions to be imported to any contribution implementation to be usable by OnlyDust platform
//

@external
func initialize_from_hash(class_hash, calldata_len, calldata : felt*) {
    assert _initialized.read() == 0;
    library_call(class_hash, INITIALIZE_SELECTOR, calldata_len, calldata);
}

@external
func set_initialized() {
    _initialized.write(1)
}

// 
// IContribution implementation
//
@external
func assign(contributor_account){
    assert IAssignmentStrategy.library_can_assign(contributor_account);
    ContributionAssigned.emit(get_contract_address(), Uint256(contributor_account));
    IAssignmentStrategy.library_on_assigned(contributor_account);
}

@external
func claim(){
    assert IAssignmentStrategy.library_can_assign(get_caller_address()) 
    ContributionClaimed.emit(get_contract_address(), Uint256(get_caller_address()));
    IAssignmentStrategy.library_on_assigned(get_caller_address());
}

@external
func unassign(contributor_account){
    assert IAssignmentStrategy.library_can_unassign(contributor_account) 
    ContributionUnassigned.emit(get_contract_address());
    IAssignmentStrategy.library_on_unassigned(contributor_account);
}

@external
func validate(contributor_account){
    assert IAssignmentStrategy.library_can_validate(contributor_account) 
    ContributionValidated.emit(get_contract_address());
    IAssignmentStrategy.library_on_validated(contributor_account);
}
