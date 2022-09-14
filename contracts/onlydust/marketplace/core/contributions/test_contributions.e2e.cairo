%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.interfaces.contributions import IContributions
from onlydust.marketplace.core.contributions.library import Contribution, Status, ContributionId
from onlydust.marketplace.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin';
const LEAD_CONTRIBUTOR_ACCOUNT = 'LeadContributor';
const PROJECT_MEMBER_ACCOUNT = 'member';
const PROJECT_ID = 'MyProject';

//
// Tests
//
@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    tempvar contributions_contract;
    %{
        context.contributions_contract = deploy_contract("./contracts/onlydust/marketplace/core/contributions/contributions.cairo", [ids.ADMIN]).contract_address
        ids.contributions_contract = context.contributions_contract
        stop_prank = start_prank(ids.ADMIN, ids.contributions_contract)
    %}
    IContributions.add_lead_contributor_for_project(
        contributions_contract, PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT
    );
    %{ stop_prank() %}
    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions_contract) %}
    IContributions.add_member_for_project(
        contributions_contract, PROJECT_ID, PROJECT_MEMBER_ACCOUNT
    );
    %{ stop_prank() %}
    return ();
}

@view
func test_contributions_e2e{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (contributions) = contributions_access.deployed();

    let CONTRIBUTOR_ID = Uint256(12, 0);
    let MEMBER_CONTRIBUTOR_ID = Uint256(13, 0);

    let UNASSIGNED_CONTRIBUTION_ID = ContributionId(1);
    let VALIDATED_CONTRIBUTION_ID = ContributionId(2);
    let CLAIMED_CONTRIBUTION_ID = ContributionId(3);

    // Create two contributions and assign them a contibutor
    with contributions {
        contributions_access.new_contribution(PROJECT_ID, 1, 0);
        contributions_access.new_contribution(PROJECT_ID, 2, 0);
        contributions_access.new_contribution(PROJECT_ID, 3, 0);

        contributions_access.assign_contributor_to_contribution(
            UNASSIGNED_CONTRIBUTION_ID, CONTRIBUTOR_ID
        );
        contributions_access.unassign_contributor_from_contribution(UNASSIGNED_CONTRIBUTION_ID);

        contributions_access.assign_contributor_to_contribution(
            VALIDATED_CONTRIBUTION_ID, CONTRIBUTOR_ID
        );

        contributions_access.claim_contribution(CLAIMED_CONTRIBUTION_ID, MEMBER_CONTRIBUTOR_ID);

        let (contribs_len, contribs) = contributions_access.all_contributions();
    }

    assert 3 = contribs_len;

    // Check unassigned contribution state
    let contribution = contribs[0];
    with contribution {
        assert_contribution_that.id_is(UNASSIGNED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.OPEN);
    }

    // Check assigned contributions state
    let contribution = contribs[1];
    with contribution {
        assert_contribution_that.id_is(VALIDATED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.ASSIGNED);
        assert_contribution_that.contributor_is(CONTRIBUTOR_ID);
    }

    // Check assigned contributions state
    let contribution = contribs[2];
    with contribution {
        assert_contribution_that.id_is(CLAIMED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.ASSIGNED);
        assert_contribution_that.contributor_is(MEMBER_CONTRIBUTOR_ID);
    }

    // Check the open contribution listing only returns the unassigned ones
    with contributions {
        let (contribs_len, contribs) = contributions_access.all_open_contributions();
    }
    assert 1 = contribs_len;

    let contribution = contribs[0];
    with contribution {
        assert_contribution_that.id_is(UNASSIGNED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.OPEN);
    }

    // Check assigned contribution state
    with contributions {
        let (contribs_len, contribs) = contributions_access.assigned_contributions(CONTRIBUTOR_ID);
    }

    assert 1 = contribs_len;

    let contribution = contribs[0];
    with contribution {
        assert_contribution_that.id_is(VALIDATED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.ASSIGNED);
        assert_contribution_that.contributor_is(CONTRIBUTOR_ID);
    }

    // Check assigned claimed contribution state
    with contributions {
        let (contribs_len, contribs) = contributions_access.assigned_contributions(
            MEMBER_CONTRIBUTOR_ID
        );
    }

    assert 1 = contribs_len;

    let contribution = contribs[0];
    with contribution {
        assert_contribution_that.id_is(CLAIMED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.ASSIGNED);
        assert_contribution_that.contributor_is(MEMBER_CONTRIBUTOR_ID);
    }

    // Check modify contribution count on unassigned works
    with contributions {
        contributions_access.modify_contribution_count(UNASSIGNED_CONTRIBUTION_ID, 10);
        let (contribution) = contributions_access.contribution(UNASSIGNED_CONTRIBUTION_ID);
    }

    with contribution {
        assert_contribution_that.id_is(UNASSIGNED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.gate_is(10);
        assert_contribution_that.status_is(Status.OPEN);
    }

    // Check validate contribution works
    with contributions {
        contributions_access.validate_contribution(VALIDATED_CONTRIBUTION_ID);
        let (contribution) = contributions_access.contribution(VALIDATED_CONTRIBUTION_ID);
    }

    with contribution {
        assert_contribution_that.id_is(VALIDATED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.COMPLETED);
    }

    // Check validate claimed contribution works
    with contributions {
        contributions_access.validate_contribution(CLAIMED_CONTRIBUTION_ID);
        let (contribution) = contributions_access.contribution(CLAIMED_CONTRIBUTION_ID);
    }

    with contribution {
        assert_contribution_that.id_is(CLAIMED_CONTRIBUTION_ID);
        assert_contribution_that.project_id_is(PROJECT_ID);
        assert_contribution_that.status_is(Status.COMPLETED);
    }

    // Check delete contribution works
    with contributions {
        contributions_access.delete_contribution(UNASSIGNED_CONTRIBUTION_ID);
        let (contribution) = contributions_access.contribution(UNASSIGNED_CONTRIBUTION_ID);
    }

    with contribution {
        assert_contribution_that.status_is(Status.NONE);
    }

    // Check open contribution deleted
    with contributions {
        let (contribs_len, contribs) = contributions_access.all_open_contributions();
    }

    assert 0 = contribs_len;

    return ();
}

//
// Libraries
//
namespace contributions_access {
    func deployed() -> (contributions_contract: felt) {
        tempvar contributions_contract;
        %{ ids.contributions_contract = context.contributions_contract %}
        return (contributions_contract,);
    }

    func new_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: felt, project_id: felt, gate: felt) {
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.new_contribution(contributions, contribution_id, project_id, gate);
        %{ stop_prank() %}
        return ();
    }

    func delete_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId) {
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.delete_contribution(contributions, contribution_id);
        %{ stop_prank() %}
        return ();
    }

    func assign_contributor_to_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId, contributor_id: Uint256) {
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.assign_contributor_to_contribution(
            contributions, contribution_id, contributor_id
        );
        %{ stop_prank() %}
        return ();
    }

    func unassign_contributor_from_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId) {
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.unassign_contributor_from_contribution(contributions, contribution_id);
        %{ stop_prank() %}
        return ();
    }

    func claim_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId, contributor_id: Uint256) {
        %{ stop_prank = start_prank(ids.PROJECT_MEMBER_ACCOUNT, ids.contributions) %}
        IContributions.claim_contribution(contributions, contribution_id, contributor_id);
        %{ stop_prank() %}
        return ();
    }

    func validate_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId) {
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.validate_contribution(contributions, contribution_id);
        %{ stop_prank() %}
        return ();
    }

    func modify_contribution_count{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId, count: felt) {
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.modify_gate(contributions, contribution_id, count);
        %{ stop_prank() %}
        return ();
    }

    func contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contribution_id: ContributionId) -> (contribution: Contribution) {
        let (contribution) = IContributions.contribution(contributions, contribution_id);
        return (contribution,);
    }

    func all_contributions{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }() -> (contribs_len: felt, contribs: Contribution*) {
        let (contribs_len, contribs) = IContributions.all_contributions(contributions);
        return (contribs_len, contribs);
    }

    func all_open_contributions{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }() -> (contribs_len: felt, contribs: Contribution*) {
        let (contribs_len, contribs) = IContributions.all_open_contributions(contributions);
        return (contribs_len, contribs);
    }

    func assigned_contributions{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, contributions: felt
    }(contributor_id: Uint256) -> (contribs_len: felt, contribs: Contribution*) {
        let (contribs_len, contribs) = IContributions.assigned_contributions(
            contributions, contributor_id
        );
        return (contribs_len, contribs);
    }
}
