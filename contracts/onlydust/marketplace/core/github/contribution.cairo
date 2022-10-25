%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.security.initializable.library import Initializable

from onlydust.marketplace.core.contribution import Contribution, assign, unassign, validate
from onlydust.marketplace.core.assignment_strategies.closable import close, reopen, is_closed
from onlydust.marketplace.core.assignment_strategies.gated import (
    change_gate,
    contributions_count_required,
    oracle_contract_address,
)
from onlydust.marketplace.core.assignment_strategies.recurring import (
    set_max_slot_count,
    max_slot_count,
    available_slot_count,
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
    repo_id: felt, issue_number: felt, stategy_class_hash: felt, calldata_len: felt, calldata: felt*
) {
    Initializable.initialize();
    Contribution.initialize();
    Contribution.initialize_strategy(stategy_class_hash, calldata_len, calldata);
    GithubContributionInitialized.emit(repo_id, issue_number);

    return ();
}
