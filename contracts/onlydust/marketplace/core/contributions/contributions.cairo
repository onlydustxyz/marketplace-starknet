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
// STORAGE
//
@storage_var
func contributions_deploy_salt_() -> (salt: felt) {
}

@event
func ContributionDeployed(contract_address) {
}

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
func past_contribution_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    contributor_account
) -> (count: felt) {
    let count = contributions.past_contributions_count(contributor_account);
    return (count,);
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
    const GITHUB_CONTRIBUTION_CLASS_HASH = 0x0;
    let (this) = get_contract_address();
    let (current_salt) = contributions_deploy_salt_.read();

    let (contract_address) = deploy(
        class_hash=GITHUB_CONTRIBUTION_CLASS_HASH,
        contract_address_salt=current_salt,
        constructor_calldata_size=5,
        constructor_calldata=cast(new (this, this, project_id, issue_number, gate,), felt*),
        deploy_from_zero=FALSE,
    );
    salt.write(value=current_salt + 1);

    ContributionDeployed.emit(contract_address);

    return Contribution(project_id, issue_number, gate);
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
