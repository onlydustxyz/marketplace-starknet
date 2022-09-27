%lang starknet

//
// Common functions to be imported to any project implementation to be usable by OnlyDust platform
//

//
// EVENTS
//
@event
func NewContributionDeployed(contract_address : felt) {
}

// 
// IProject implementation
//

@external
func new_contribution(contribution_hash, assignment_strategy_hash, calldata_len : felt, calldata : felt*) 
    only_lead_contributor {

    let contract = deploy(contribution_hash, assignment_strategy_hash)
    ContributionDeployed.emit(...);

    loop {
        let class_hash = calldata[0]
        IOnlyDust.assert_hash_allowed(only_dust_contract, class_hash)
        IContribution.initialize_from_hash(contract, class_hash = strategy_hash, calldata_len = calldata[1], calldata = calldata+2);
        let calldata_len = calldata_len - (calldata[1] + 2)
        let calldata = calldata + calldata[1] + 2
    }

    IContribution.set_initialized(contract)
}

//
// OTHER MANAGEMENT FUNCTIONS
//
@external
func initialize_from_hash(class_hash, calldata_len, calldata : felt*) {
    assert _initialized.read() == 0;
    library_call(class_hash, INITIALIZE_SELECTOR, calldata_len, calldata);
    _initialized.write(1);

    return ();
}