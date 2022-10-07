%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.marketplace.test.libraries.contributions import assert_contribution_that
from onlydust.marketplace.core.contributions.library import Contribution, ContributionId
from onlydust.marketplace.interfaces.contributor_oracle import IContributorOracle
from onlydust.marketplace.interfaces.contribution import IContribution

//
// INTERFACES
//
@contract_interface
namespace IContributions {
    func new_contribution(project_id: felt, issue_number: felt, gate: felt) -> (
        contribution: Contribution
    ) {
    }

    func delete_contribution(contribution_id: ContributionId) {
    }

    func assign_contributor_to_contribution(
        contribution_id: ContributionId, contributor_account_adress: felt
    ) {
    }

    func unassign_contributor_from_contribution(
        contribution_id: ContributionId, contributor_account_adress: felt
    ) {
    }

    func claim_contribution(contribution_id: ContributionId, contributor_id: Uint256) {
    }

    func validate_contribution(contribution_id: ContributionId, contributor_account_adress: felt) {
    }

    func modify_gate(contribution_id: ContributionId, gate: felt) {
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

@contract_interface
namespace IGithubContribution {
    func modify_gate(gate: felt) {
    }

    func delete() {
    }
}

//
// CONSTANTS
//
const ADMIN = 'admin';
const CALLER_ACCOUNT = 0;
const PROJECT_ID = 'starkonquest';
const CONTRIBUTOR_ACCOUNT = 'greg';

//
// Tests
//
@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    tempvar contributions_contract;
    %{
        print('declaring github contribution')
        contribution_class_hash = declare("./contracts/onlydust/marketplace/core/github/contribution.cairo", config={"wait_for_acceptance": True}).class_hash
        print(f'declared github contribution: {hex(contribution_class_hash)}')
        print('deploying contributions')
        declared_contributions = declare("./contracts/onlydust/marketplace/core/contributions/contributions.cairo", config={"wait_for_acceptance": True})
        print(f'declared contributions: {hex(declared_contributions.class_hash)}')
        prepared_contributions = prepare(declared_contributions, [ids.ADMIN])
        deployed_contributions = deploy(prepared_contributions)
        context.contributions_contract = deployed_contributions.contract_address
        print(f'deployed contract: {hex(context.contributions_contract)}')
        ids.contributions_contract = context.contributions_contract
    %}
    return ();
}

func set_caller_as_lead_contributor{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    let (contributions_contract) = contributions_access.deployed();

    %{ stop_prank = start_prank(ids.ADMIN, ids.contributions_contract) %}
    IContributions.add_lead_contributor_for_project(
        contributions_contract, PROJECT_ID, CALLER_ACCOUNT
    );
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.CALLER_ACCOUNT, ids.contributions_contract) %}
    IContributions.remove_member_for_project(contributions_contract, PROJECT_ID, CALLER_ACCOUNT);
    %{ stop_prank() %}
    return ();
}

func set_caller_as_project_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    alloc_locals;
    set_caller_as_lead_contributor();
    let (contributions_contract) = contributions_access.deployed();

    %{ stop_prank = start_prank(ids.CALLER_ACCOUNT, ids.contributions_contract) %}
    IContributions.add_member_for_project(contributions_contract, PROJECT_ID, CALLER_ACCOUNT);
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN, ids.contributions_contract) %}
    IContributions.remove_lead_contributor_for_project(
        contributions_contract, PROJECT_ID, CALLER_ACCOUNT
    );
    %{ stop_prank() %}
    return ();
}

@view
func test_contribution_lifetime_with_legacy_api{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local contributions_contract) = contributions_access.deployed();

    set_caller_as_lead_contributor();

    let (contribution1: Contribution) = IContributions.new_contribution(
        contributions_contract, PROJECT_ID, 235, 0
    );
    let (contribution2: Contribution) = IContributions.new_contribution(
        contributions_contract, PROJECT_ID, 236, 2
    );

    let contribution_id = contribution1.id;
    IContributions.assign_contributor_to_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.unassign_contributor_from_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.assign_contributor_to_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.validate_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );

    let (count) = IContributorOracle.past_contribution_count(
        contributions_contract, CONTRIBUTOR_ACCOUNT
    );
    assert count = 1;

    let contribution_id = contribution2.id;
    IContributions.modify_gate(contributions_contract, contribution_id, 1);
    IContributions.assign_contributor_to_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.unassign_contributor_from_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.delete_contribution(contributions_contract, contribution_id);

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": ids.contribution1.id.inner, "project_id": ids.PROJECT_ID,  "issue_number": 235, "gate": 0}},
               {"name": "ContributionCreated", "data": {"contribution_id": ids.contribution2.id.inner, "project_id": ids.PROJECT_ID,  "issue_number": 236, "gate": 2}},
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contribution1.id.inner, "contributor_id": {"low": ids.CONTRIBUTOR_ACCOUNT, "high": 0}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": ids.contribution1.id.inner}},
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contribution1.id.inner, "contributor_id": {"low": ids.CONTRIBUTOR_ACCOUNT, "high": 0}}},
               {"name": "ContributionValidated", "data": {"contribution_id": ids.contribution1.id.inner}},
               {"name": "ContributionGateChanged", "data": {"contribution_id": ids.contribution2.id.inner, "gate": 1}},
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contribution2.id.inner, "contributor_id": {"low": ids.CONTRIBUTOR_ACCOUNT, "high": 0}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": ids.contribution2.id.inner}},
               {"name": "ContributionDeleted", "data": {"contribution_id": ids.contribution2.id.inner}},
           )
    %}
    return ();
}

@view
func test_contribution_claimed_with_legacy_api{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local contributions_contract) = contributions_access.deployed();

    set_caller_as_lead_contributor();

    let (contribution1: Contribution) = IContributions.new_contribution(
        contributions_contract, PROJECT_ID, 235, 0
    );

    set_caller_as_project_member();

    let contribution_id = contribution1.id;
    IContributions.claim_contribution(
        contributions_contract, contribution_id, Uint256(CALLER_ACCOUNT, 0)
    );

    set_caller_as_lead_contributor();

    IContributions.validate_contribution(contributions_contract, contribution_id, CALLER_ACCOUNT);

    let (count) = IContributorOracle.past_contribution_count(
        contributions_contract, CALLER_ACCOUNT
    );
    assert count = 1;

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": ids.contribution1.id.inner, "project_id": ids.PROJECT_ID,  "issue_number": 235, "gate": 0}},
               {"name": "ContributionClaimed", "data": {"contribution_id": ids.contribution1.id.inner, "contributor_id": {"low": ids.CALLER_ACCOUNT, "high": 0}}},
               {"name": "ContributionValidated", "data": {"contribution_id": ids.contribution1.id.inner}},
           )
    %}
    return ();
}

@view
func test_contribution_lifetime_with_new_api{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let (local contributions_contract) = contributions_access.deployed();

    set_caller_as_lead_contributor();

    let (contribution1: Contribution) = IContributions.new_contribution(
        contributions_contract, PROJECT_ID, 235, 2
    );

    let contribution_contract = contribution1.id.inner;
    IGithubContribution.modify_gate(contribution_contract, 0);
    IContribution.assign(contribution_contract, CONTRIBUTOR_ACCOUNT);
    IContribution.unassign(contribution_contract, CONTRIBUTOR_ACCOUNT);
    IContribution.assign(contribution_contract, CONTRIBUTOR_ACCOUNT);
    IContribution.validate(contribution_contract, CONTRIBUTOR_ACCOUNT);

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": ids.contribution1.id.inner, "project_id": ids.PROJECT_ID,  "issue_number": 235, "gate": 2}},
               {"name": "ContributionGateChanged", "data": {"contribution_id": ids.contribution1.id.inner, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contribution1.id.inner, "contributor_id": {"low": ids.CONTRIBUTOR_ACCOUNT, "high": 0}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": ids.contribution1.id.inner}},
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contribution1.id.inner, "contributor_id": {"low": ids.CONTRIBUTOR_ACCOUNT, "high": 0}}},
               {"name": "ContributionValidated", "data": {"contribution_id": ids.contribution1.id.inner}},
           )
    %}

    return ();
}

//
// Libraries
//
namespace contributions_access {
    func deployed() -> (address: felt) {
        tempvar contributions_contract;
        %{ ids.contributions_contract = context.contributions_contract %}
        return (contributions_contract,);
    }
}
