%lang starknet

from starkware.starknet.common.syscalls import deploy
from onlydust.marketplace.interfaces.contribution import IContribution

//
// Common functions to be imported to any project implementation to be usable by OnlyDust platform
//

//
// EVENTS
//
@event
func ContributionDeployed(contract_address: felt) {
}

//
// IProject implementation
//

@external
func new_contribution(
    contribution_hash, assignment_strategy_hash, calldata_len: felt, calldata: felt*
) {
    // only_lead_contributor
    let contract = deploy(contribution_hash, assignment_strategy_hash);
    ContributionDeployed.emit(contract);

    IContribution.initialize_strategy(contract, assignment_strategy_hash, calldata_len, calldata);
}
