%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.marketplace.test.libraries.contributions import assert_contribution_that
from onlydust.marketplace.core.contributions.library import Contribution, ContributionId
from onlydust.marketplace.interfaces.contributor_oracle import IContributorOracle
from onlydust.marketplace.interfaces.contribution import IContribution
from onlydust.marketplace.interfaces.project import IProject

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
    // Composite
    func strategies() -> (strategies_len: felt, strategies: felt*) {
    }

    // Closable
    func close() {
    }
    func reopen() {
    }
    func is_closed() -> (is_closed: felt) {
    }

    // Gated
    func change_gate(new_past_contributions_count_required) {
    }
    func oracle_contract_address() -> (oracle_contract_address: felt) {
    }
    func contributions_count_required() -> (contributions_count_required: felt) {
    }

    // Recurring
    func available_slot_count() -> (slot_count: felt) {
    }
    func max_slot_count() -> (slot_count: felt) {
    }
    func set_max_slot_count(new_max_slot_count: felt) {
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
    %{
        context.contribution_class_hash = declare("./contracts/onlydust/marketplace/core/contribution.cairo", config={"wait_for_acceptance": True}).class_hash
        context.github_contribution_class_hash = declare("./contracts/onlydust/marketplace/core/github/contribution.cairo", config={"wait_for_acceptance": True}).class_hash
        context.closable_class_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/closable.cairo", config={"wait_for_acceptance": True}).class_hash
        context.recurring_class_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/recurring.cairo", config={"wait_for_acceptance": True}).class_hash
        context.composite_class_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/composite.cairo", config={"wait_for_acceptance": True}).class_hash
        context.gated_class_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/gated.cairo", config={"wait_for_acceptance": True}).class_hash
        context.access_control_class_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/access_control.cairo", config={"wait_for_acceptance": True}).class_hash

        print(f'=== Class hashes declared:')
        print(f'const CONTRIBUTION = {hex(context.contribution_class_hash)};')
        print(f'const GITHUB = {hex(context.github_contribution_class_hash)};')
        print(f'const CLOSABLE = {hex(context.closable_class_hash)};')
        print(f'const RECURRING = {hex(context.recurring_class_hash)};')
        print(f'const COMPOSITE = {hex(context.composite_class_hash)};')
        print(f'const GATED = {hex(context.gated_class_hash)};')
        print(f'const ACCESS_CONTROL = {hex(context.access_control_class_hash)};')

        declared_contributions = declare("./contracts/onlydust/marketplace/core/contributions/contributions.cairo", config={"wait_for_acceptance": True})
        prepared_contributions = prepare(declared_contributions, [ids.ADMIN])
        context.contributions_contract = deploy(prepared_contributions).contract_address
        print(f'\nDeployed Contributions contract: {hex(context.contributions_contract)}')
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
    IContributions.assign_contributor_to_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.unassign_contributor_from_contribution(
        contributions_contract, contribution_id, CONTRIBUTOR_ACCOUNT
    );
    IContributions.delete_contribution(contributions_contract, contribution_id);

    %{
        expect_events(
                {"name": "ContributionDeployed", "data": [ids.contribution1.id.inner], "from_address": ids.contributions_contract},
                {"name": "GithubContributionInitialized", "data": [ids.PROJECT_ID, 235], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionGateChanged", "data": [0], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssignmentRecurringMaxSlotsUpdated", "data": [1], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssignmentStrategyInitialized", "data": [context.composite_class_hash], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionDeployed", "data": [ids.contribution2.id.inner], "from_address": ids.contributions_contract},
                {"name": "GithubContributionInitialized", "data": [ids.PROJECT_ID, 236], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionGateChanged", "data": [0], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionAssignmentRecurringMaxSlotsUpdated", "data": [1], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionAssignmentStrategyInitialized", "data": [context.composite_class_hash], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionAssigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [0], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionUnassigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [0], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionValidated", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution1.id.inner},
                {"name": "ContributionAssigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [0], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionUnassigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution2.id.inner},
                {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution2.id.inner},
               {"name": "ContributionClosed", "data": [], "from_address": ids.contribution2.id.inner},
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
               {"name": "ContributionDeployed", "data": [ids.contribution1.id.inner], "from_address": ids.contributions_contract},
               {"name": "GithubContributionInitialized", "data": [ids.PROJECT_ID, 235], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionGateChanged", "data": [0], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionAssignmentRecurringMaxSlotsUpdated", "data": [1], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionAssignmentStrategyInitialized", "data": [context.composite_class_hash], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionAssigned", "data": [ids.CALLER_ACCOUNT], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [0], "from_address": ids.contribution1.id.inner},
               {"name": "ContributionValidated", "data": [ids.CALLER_ACCOUNT], "from_address": ids.contribution1.id.inner},
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

    // TODO: use IProject instead
    let (contribution: Contribution) = IContributions.new_contribution(
        contributions_contract, PROJECT_ID, 235, 2
    );

    let contribution_contract = contribution.id.inner;

    // Test Closable
    let (is_closed) = IGithubContribution.is_closed(contribution_contract);
    assert FALSE = is_closed;
    IGithubContribution.close(contribution_contract);
    let (is_closed) = IGithubContribution.is_closed(contribution_contract);
    assert TRUE = is_closed;
    IGithubContribution.reopen(contribution_contract);
    let (is_closed) = IGithubContribution.is_closed(contribution_contract);
    assert FALSE = is_closed;

    // Test Gated
    let (contributions_count_required) = IGithubContribution.contributions_count_required(
        contribution_contract
    );
    assert 0 = contributions_count_required;
    let (oracle_contract_address) = IGithubContribution.oracle_contract_address(
        contribution_contract
    );
    assert oracle_contract_address = contributions_contract;
    IGithubContribution.change_gate(contribution_contract, 1);
    let (contributions_count_required) = IGithubContribution.contributions_count_required(
        contribution_contract
    );
    assert 1 = contributions_count_required;
    IGithubContribution.change_gate(contribution_contract, 0);

    // Test Recurring
    let (available_slot_count) = IGithubContribution.available_slot_count(contribution_contract);
    assert 1 = available_slot_count;
    let (max_slot_count) = IGithubContribution.max_slot_count(contribution_contract);
    assert 1 = max_slot_count;

    IGithubContribution.set_max_slot_count(contribution_contract, 2);

    let (available_slot_count) = IGithubContribution.available_slot_count(contribution_contract);
    assert 2 = available_slot_count;
    let (max_slot_count) = IGithubContribution.max_slot_count(contribution_contract);
    assert 2 = max_slot_count;

    // Contribution lifecycle
    IContribution.assign(contribution_contract, CONTRIBUTOR_ACCOUNT);
    IContribution.unassign(contribution_contract, CONTRIBUTOR_ACCOUNT);
    IContribution.assign(contribution_contract, CONTRIBUTOR_ACCOUNT);
    IContribution.validate(contribution_contract, CONTRIBUTOR_ACCOUNT);

    %{
        expect_events(
               {"name": "ContributionDeployed", "data": [ids.contribution_contract], "from_address": ids.contributions_contract},
               {"name": "GithubContributionInitialized", "data": [ids.PROJECT_ID, 235], "from_address": ids.contribution_contract},
               {"name": "ContributionGateChanged", "data": [0], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringMaxSlotsUpdated", "data": [1], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentStrategyInitialized", "data": [context.composite_class_hash], "from_address": ids.contribution_contract},
               {"name": "ContributionClosed", "data": [], "from_address": ids.contribution_contract},
               {"name": "ContributionReopened", "data": [], "from_address": ids.contribution_contract},
               {"name": "ContributionGateChanged", "data": [1], "from_address": ids.contribution_contract},
               {"name": "ContributionGateChanged", "data": [0], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [2], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringMaxSlotsUpdated", "data": [2], "from_address": ids.contribution_contract},
               {"name": "ContributionAssigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution_contract},
               {"name": "ContributionUnassigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [2], "from_address": ids.contribution_contract},
               {"name": "ContributionAssigned", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution_contract},
               {"name": "ContributionAssignmentRecurringAvailableSlotsUpdated", "data": [1], "from_address": ids.contribution_contract},
               {"name": "ContributionValidated", "data": [ids.CONTRIBUTOR_ACCOUNT], "from_address": ids.contribution_contract},
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
