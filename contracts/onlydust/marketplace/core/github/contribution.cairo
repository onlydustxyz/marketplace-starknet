%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.security.initializable.library import Initializable

from onlydust.marketplace.core.contribution import initialize_strategy, assign, unassign, validate
from onlydust.marketplace.core.assignment_strategies.closable import close, reopen, is_closed
from onlydust.marketplace.core.assignment_strategies.gated import (
    change_gate,
    contributions_count_required,
    oracle_contract_address,
)

//
// Events
//
@event
func GithubContributionInitialized(project_id: felt, issue_number: felt) {
}

//
// Init
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    calldata_len: felt, calldata: felt*
) {
    Initializable.initialize();

    let repo_id = calldata[0];
    let issue_number = calldata[1];
    let stategy_class_hash = calldata[2];

    let new_calldata_len = calldata_len - 3;
    let new_calldata = calldata + 3;
    initialize_strategy(stategy_class_hash, new_calldata_len, new_calldata);

    GithubContributionInitialized.emit(repo_id, issue_number);

    return ();
}
