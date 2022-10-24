%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_contract_address, get_tx_info, TxInfo
from openzeppelin.security.initializable.library import Initializable

from onlydust.marketplace.interfaces.project import IProject
from onlydust.marketplace.interfaces.contributor_oracle import IContributorOracle

from onlydust.marketplace.core.contribution import initialize_strategy, assign, unassign, validate
from onlydust.marketplace.core.assignment_strategies.closable import close, reopen, is_closed
from onlydust.marketplace.core.assignment_strategies.gated import (
    change_gate,
    contributions_count_required,
    oracle_contract_address,
)

struct Status {
    NONE: felt,
    OPEN: felt,
    ASSIGNED: felt,
    COMPLETED: felt,
    ABANDONED: felt,
}

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
    let (initialized) = Initializable.initialized();
    assert FALSE = initialized;
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
