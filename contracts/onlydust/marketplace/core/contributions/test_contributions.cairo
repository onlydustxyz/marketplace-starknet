%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.marketplace.core.contributions.library import (
    contributions,
    Status,
    past_contributions_,
    ContributionId,
)
from onlydust.marketplace.core.contributions.access_control import access_control

from onlydust.marketplace.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin';
const PROJECT_ID = 'MyProject';
const LEAD_CONTRIBUTOR_ACCOUNT = 'lead';
const PROJECT_MEMBER_ACCOUNT = 'member';
const CONTRIBUTOR = 'contributor';

@view
func test_lead_contributor_can_be_added_and_removed{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();
    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.add_lead_contributor_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT);
    contributions.remove_lead_contributor_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT);
    %{ stop_prank() %}

    %{
        expect_events(
            { "name": "LeadContributorAdded", "data": { "project_id": ids.PROJECT_ID,  "lead_contributor_account":  ids.LEAD_CONTRIBUTOR_ACCOUNT }},
            { "name": "LeadContributorRemoved", "data": { "project_id": ids.PROJECT_ID,  "lead_contributor_account": ids.LEAD_CONTRIBUTOR_ACCOUNT }},
        )
    %}

    return ();
}

@view
func lead_can_test_new_contribution_can_be_added{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    fixture.initialize();

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0);
    let (contribution2) = contributions.new_contribution(PROJECT_ID, 2, 0);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionCreated", "data": {"contribution_id": 2, "project_id": ids.PROJECT_ID,  "issue_number": 2, "gate": 0}},
           )
    %}
    return ();
}

@view
func test_new_contribution_can_be_added_by_lead_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    fixture.initialize();

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.add_lead_contributor_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT);
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ stop_prank() %}

    return ();
}

@view
func test_same_contribution_cannot_be_added_twice{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    fixture.initialize();

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contributions: Contribution already exist")
    %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0);
    let (contribution2) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ stop_prank() %}

    return ();
}

@view
func test_lead_contributor_can_delete_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    fixture.initialize();

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.delete_contribution(contribution1.id);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionDeleted", "data": {"contribution_id": 1}}
           )
    %}

    return ();
}

@view
func test_anyone_cannot_delete_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    fixture.initialize();

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ stop_prank() %}

    %{ expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required") %}
    contributions.delete_contribution(contribution1.id);

    return ();
}

@view
func test_only_open_delete_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    fixture.initialize();

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ stop_prank() %}

    %{ expect_revert(error_message="Contributions: Contribution is not OPEN") %}

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    // set status to ASSIGNED
    contributions.assign_contributor_to_contribution(contribution1.id, CONTRIBUTOR);
    contributions.delete_contribution(contribution1.id);
    %{ stop_prank() %}

    return ();
}

@view
func test_lead_can_assign_contribution_to_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (contribution) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": ids.CONTRIBUTOR, "high": 0}}},
           )
    %}
    return ();
}

@view
func test_anyone_cannot_assign_contribution_to_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required")
    %}
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);

    return ();
}

@view
func test_cannot_assign_non_existent_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) 
        expect_revert()
    %}
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_assign_twice_a_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{ expect_revert(error_message="Contributions: Contribution is not OPEN") %}
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_assign_contribution_to_non_eligible_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 3);
    %{ expect_revert(error_message="Contributions: Contributor is not eligible") %}
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_can_assign_gated_contribution_eligible_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let gated_contribution_id = ContributionId(2);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    // Create a non-gated contribution
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);

    // Create a gated contribution
    let (_) = contributions.new_contribution(PROJECT_ID, 2, 1);

    // Assign and validate the non-gated contribution
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    contributions.validate_contribution(contribution_id, CONTRIBUTOR);

    // Assign and validate the gated contribution
    contributions.assign_contributor_to_contribution(gated_contribution_id, CONTRIBUTOR);
    contributions.validate_contribution(gated_contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    assert 2 = contributions.past_contributions_count(CONTRIBUTOR);

    return ();
}

@view
func test_contribution_creation_with_invalid_project_id_is_reverted{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contributions: Invalid project ID")
    %}
    let (_) = contributions.new_contribution(0, 1, 0);
    %{ stop_prank() %}

    return ();
}

@view
func test_contribution_creation_with_invalid_contribution_count_is_reverted{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contributions: Invalid gate")
    %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, -1);
    %{ stop_prank() %}

    return ();
}

@view
func test_anyone_cannot_add_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    %{ expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required") %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);

    return ();
}

@view
func test_lead_can_unassign_contribution_from_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    contributions.unassign_contributor_from_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID, "issue_number": 1, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": ids.CONTRIBUTOR, "high": 0}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": 1}},
           )
    %}

    return ();
}

@view
func test_anyone_cannot_unassign_contribution_from_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required")
    %}
    contributions.unassign_contributor_from_contribution(contribution_id, CONTRIBUTOR);

    return ();
}

@view
func test_cannot_unassign_from_non_existent_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) 
        expect_revert()
    %}
    contributions.unassign_contributor_from_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_unassign_contribution_if_not_assigned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.unassign_contributor_from_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_lead_can_validate_assigned_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    contributions.validate_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": ids.CONTRIBUTOR, "high": 0}}},
               {"name": "ContributionValidated", "data": {"contribution_id": 1}},
           )
    %}

    return ();
}

@view
func test_anyone_cannot_validate_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required")
    %}
    contributions.validate_contribution(contribution_id, CONTRIBUTOR);

    return ();
}

@view
func test_cannot_validate_non_existent_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) 
        expect_revert()
    %}
    contributions.validate_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_validate_contribution_if_not_assigned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.validate_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    return ();
}

@view
func test_lead_can_modify_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let validator_account = 'validator';

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    contributions.modify_gate(contribution_id, 3);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionGateChanged", "data": {"contribution_id": 1, "gate": 3}},
           )
    %}

    return ();
}

@view
func test_anyone_cannot_modify_gate{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let validator_account = 'validator';

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{
        stop_prank ()
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role require")
    %}
    contributions.modify_gate(contribution_id, 3);

    return ();
}

@view
func test_anyone_can_get_past_contributions_count{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();
    fixture.validate_two_contributions(CONTRIBUTOR);

    assert 2 = contributions.past_contributions_count(CONTRIBUTOR);

    return ();
}

@view
func test_lead_can_add_member_to_project{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    contributions.add_member_for_project(PROJECT_ID, CONTRIBUTOR);
    %{ stop_prank() %}

    %{
        expect_events(
            { "name": "ProjectMemberAdded", "data": { "project_id": ids.PROJECT_ID,  "contributor_account":  ids.CONTRIBUTOR }},
        )
    %}
    return ();
}

@view
func test_lead_can_remove_member_to_project{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    contributions.remove_member_for_project(PROJECT_ID, CONTRIBUTOR);
    %{ stop_prank() %}

    %{
        expect_events(
            { "name": "ProjectMemberRemoved", "data": { "project_id": ids.PROJECT_ID,  "contributor_account":  ids.CONTRIBUTOR }},
        )
    %}
    return ();
}

@view
func test_project_member_can_claim_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let contributor_id = Uint256(CONTRIBUTOR, 0);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (contribution) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.PROJECT_MEMBER_ACCOUNT) %}
    contributions.claim_contribution(contribution_id, contributor_id);
    %{ stop_prank() %}

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionClaimed", "data": {"contribution_id": 1, "contributor_id": {"low": ids.CONTRIBUTOR, "high": 0}}},
           )
    %}
    return ();
}

@view
func test_anyone_cannot_claim_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let contributor_id = Uint256(CONTRIBUTOR, 0);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: PROJECT_MEMBER or LEAD_CONTRIBUTOR role required")
    %}
    contributions.claim_contribution(contribution_id, contributor_id);

    return ();
}

@view
func test_cannot_claim_non_existent_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let contributor_id = Uint256(CONTRIBUTOR, 0);

    %{
        stop_prank = start_prank(ids.PROJECT_MEMBER_ACCOUNT) 
        expect_revert()
    %}
    contributions.claim_contribution(contribution_id, contributor_id);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_claim_twice_a_contribution{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let contributor_id = Uint256(CONTRIBUTOR, 0);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.PROJECT_MEMBER_ACCOUNT) %}
    contributions.claim_contribution(contribution_id, contributor_id);
    %{ expect_revert(error_message="Contributions: Contribution is not OPEN") %}
    contributions.claim_contribution(contribution_id, contributor_id);
    %{ stop_prank() %}

    return ();
}

@view
func test_cannot_claim_contribution_as_non_eligible_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let contributor_id = Uint256(CONTRIBUTOR, 0);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 3);
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.PROJECT_MEMBER_ACCOUNT) %}
    %{ expect_revert(error_message="Contributions: Contributor is not eligible") %}
    contributions.claim_contribution(contribution_id, contributor_id);
    %{ stop_prank() %}

    return ();
}

@view
func test_can_claim_gated_contribution_as_eligible_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    fixture.initialize();

    let contribution_id = ContributionId(1);
    let gated_contribution_id = ContributionId(2);
    let contributor_id = Uint256(CONTRIBUTOR, 0);

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    // Create a non-gated contribution
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0);

    // Create a gated contribution
    let (_) = contributions.new_contribution(PROJECT_ID, 2, 1);

    // Assign and validate the non-gated contribution
    contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
    contributions.validate_contribution(contribution_id, CONTRIBUTOR);
    %{ stop_prank() %}

    assert 1 = contributions.past_contributions_count(CONTRIBUTOR);

    %{ stop_prank = start_prank(ids.PROJECT_MEMBER_ACCOUNT) %}
    // Claim the gated contribution
    contributions.claim_contribution(gated_contribution_id, contributor_id);
    %{ stop_prank() %}

    return ();
}

namespace fixture {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        contributions.initialize(ADMIN);
        %{ stop_prank = start_prank(ids.ADMIN) %}
        access_control.grant_lead_contributor_role_for_project(
            PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT
        );
        %{ stop_prank() %}
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
        access_control.grant_member_role_for_project(PROJECT_ID, PROJECT_MEMBER_ACCOUNT);
        %{ stop_prank() %}
        return ();
    }

    func validate_two_contributions{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contributor_account_address: felt) {
        let contribution_id = ContributionId(1);
        let gated_contribution_id = ContributionId(2);

        %{ stop_prank = start_prank(ids.ADMIN) %}
        access_control.grant_lead_contributor_role_for_project('Random', LEAD_CONTRIBUTOR_ACCOUNT);
        %{ stop_prank() %}

        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
        // Create a non-gated contribution
        let (contribution) = contributions.new_contribution('Random', 1, 0);

        // Create a gated contribution
        let (contribution) = contributions.new_contribution('Random', 2, 1);

        // Assign and validate the non-gated contribution
        contributions.assign_contributor_to_contribution(contribution_id, CONTRIBUTOR);
        contributions.validate_contribution(contribution_id, CONTRIBUTOR);

        // Assign and validate the gated contribution
        contributions.assign_contributor_to_contribution(gated_contribution_id, CONTRIBUTOR);
        contributions.validate_contribution(gated_contribution_id, CONTRIBUTOR);
        %{ stop_prank() %}

        assert 2 = contributions.past_contributions_count(CONTRIBUTOR);

        return ();
    }
}
