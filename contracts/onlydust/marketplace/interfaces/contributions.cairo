%lang starknet

from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.core.contributions.library import Contribution, ContributionId

@contract_interface
namespace IContributions {
    func new_contribution(project_id: felt, issue_number: felt, gate: felt) -> (
        contribution: Contribution
    ) {
    }

    func delete_contribution(contribution_id: ContributionId) {
    }

    func contribution(contribution_id: ContributionId) -> (contribution: Contribution) {
    }

    func past_contributions(contributor_id: Uint256) -> (num_contributions: felt) {
    }

    func all_contributions() -> (contributions_len: felt, contributions: Contribution*) {
    }

    func all_open_contributions() -> (contributions_len: felt, contributions: Contribution*) {
    }

    func assigned_contributions(contributor_id: Uint256) -> (
        contributions_len: felt, contributions: Contribution*
    ) {
    }

    func assign_contributor_to_contribution(
        contribution_id: ContributionId, contributor_id: Uint256
    ) {
    }

    func unassign_contributor_from_contribution(contribution_id: ContributionId) {
    }

    func claim_contribution(contribution_id: ContributionId, contributor_id: Uint256) {
    }

    func validate_contribution(contribution_id: ContributionId) {
    }

    func modify_gate(contribution_id: ContributionId, gate: felt) {
    }

    func grant_admin_role(address: felt) {
    }

    func revoke_admin_role(address: felt) {
    }

    func add_lead_contributor_for_project(project_id: felt, lead_contributor_account: felt) {
    }

    func remove_lead_contributor_for_project(project_id: felt, lead_contributor_account: felt) {
    }

    func add_member_for_project(project_id: felt, contributor_account: felt) {
    }

    func remove_member_for_project(project_id: felt, contributor_account: felt) {
    }
}
