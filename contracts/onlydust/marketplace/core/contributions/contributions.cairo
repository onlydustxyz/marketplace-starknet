%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.upgrades.library import Proxy

from onlydust.marketplace.core.contributions.library import (
    contributions,
    Contribution,
    ContributionId,
)
from onlydust.marketplace.core.contributions.access_control import access_control

// DO NOT REMOVE THOSE IMPORTS
// They are mandatory to make this contract upgradable and migratable
from onlydust.marketplace.library.migration_library import (
    migratable_proxy,
    implementation,
    proxy_admin,
    set_implementation,
    set_implementation_with_migration,
    set_proxy_admin,
)

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
    contributions.initialize(admin);
    return ();
}

@external
func initializer{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    proxy_admin: felt
) {
    migratable_proxy.initializer(proxy_admin);
    contributions.initialize(proxy_admin);
    return ();
}

//
// Views
//
@view
func contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contribution_id: ContributionId
) -> (contribution: Contribution) {
    return contributions.contribution(contribution_id);
}

@view
func past_contributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_id: Uint256
) -> (num_contributions: felt) {
    return contributions.past_contributions(contributor_id);
}

@view
func all_contributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    contributions_len: felt, contributions: Contribution*
) {
    return contributions.all_contributions();
}

@view
func all_open_contributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    contributions_len: felt, contributions: Contribution*
) {
    return contributions.all_open_contributions();
}

@view
func assigned_contributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_id: Uint256
) -> (contributions_len: felt, contributions: Contribution*) {
    return contributions.assigned_contributions(contributor_id);
}

@view
func eligible_contributions{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_id: Uint256
) -> (contributions_len: felt, contributions: Contribution*) {
    return contributions.eligible_contributions(contributor_id);
}

//
// Externals
//

@external
func grant_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    return access_control.grant_admin_role(address);
}

@external
func revoke_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    return access_control.revoke_admin_role(address);
}

@external
func new_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    project_id: felt, issue_number: felt, gate: felt
) -> (contribution: Contribution) {
    return contributions.new_contribution(project_id, issue_number, gate);
}

@external
func delete_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contribution_id: ContributionId
) {
    return contributions.delete_contribution(contribution_id);
}

@external
func assign_contributor_to_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(contribution_id: ContributionId, contributor_id: Uint256) {
    return contributions.assign_contributor_to_contribution(contribution_id, contributor_id);
}

@external
func unassign_contributor_from_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(contribution_id: ContributionId) {
    return contributions.unassign_contributor_from_contribution(contribution_id);
}

@external
func claim_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contribution_id: ContributionId, contributor_id: Uint256
) {
    return contributions.claim_contribution(contribution_id, contributor_id);
}

@external
func validate_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contribution_id: ContributionId
) {
    return contributions.validate_contribution(contribution_id);
}

@external
func modify_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contribution_id: ContributionId, gate: felt
) {
    return contributions.modify_gate(contribution_id, gate);
}

@external
func add_lead_contributor_for_project{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(project_id: felt, lead_contributor_account: felt) {
    return contributions.add_lead_contributor_for_project(project_id, lead_contributor_account);
}

@external
func remove_lead_contributor_for_project{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(project_id: felt, lead_contributor_account: felt) {
    return contributions.remove_lead_contributor_for_project(project_id, lead_contributor_account);
}

@external
func add_member_for_project{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    project_id: felt, contributor_account: felt
) {
    return contributions.add_member_for_project(project_id, contributor_account);
}

@external
func remove_member_for_project{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    project_id: felt, contributor_account: felt
) {
    return contributions.remove_member_for_project(project_id, contributor_account);
}
