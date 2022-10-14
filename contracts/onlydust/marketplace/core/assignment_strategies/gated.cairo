%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.bool import TRUE, FALSE

from contracts.onlydust.marketplace.interfaces.contributor_oracle import IContributorOracle

//
// This strategy checks that the contributor has
//

@storage_var
func assignment_strategy__gated__oracle_contract_address() -> (oracle_contract_address: felt) {
}

@storage_var
func assignment_strategy__gated__contributions_count_required() -> (
    contributions_count_required: felt
) {
}

@event
func ContributionGateChanged(contribution_account: felt, contributions_count_required: felt) {
}

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    oracle_contract_address, past_contributions_count_required
) {
    assignment_strategy__gated__oracle_contract_address.write(oracle_contract_address);

    assignment_strategy__gated__contributions_count_required.write(
        past_contributions_count_required
    );

    return ();
}

@view
func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) {
    let (oracle) = assignment_strategy__gated__oracle_contract_address.read();

    let (count_done) = IContributorOracle.past_contribution_count(oracle, contributor_account);
    let (count_required) = assignment_strategy__gated__contributions_count_required.read();

    let done_enough = is_le(count_required, count_done);

    with_attr error_message("Gated: No enough contributions done.") {
        assert TRUE = done_enough;
    }

    return ();
}

@view
func assert_can_unassign(contributor_account) {
    return ();
}

@view
func assert_can_validate(contributor_account) {
    return ();
}

@external
func on_assigned(contributor_account) {
    return ();
}

@external
func on_unassigned(contributor_account) {
    return ();
}

@external
func on_validated(contributor_account) {
    return ();
}

//
// MANAGEMENT FUNCTIONS
//

@external
func change_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    new_past_contributions_count_required
) {
    assignment_strategy__gated__contributions_count_required.write(
        new_past_contributions_count_required
    );

    let (contribution_id) = get_contract_address();
    ContributionGateChanged.emit(contribution_id, new_past_contributions_count_required);

    return ();
}

@view
func oracle_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    oracle_contract_address: felt
) {
    return assignment_strategy__gated__oracle_contract_address.read();
}

@view
func contributions_count_required{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (contributions_count_required: felt) {
    return assignment_strategy__gated__contributions_count_required.read();
}
