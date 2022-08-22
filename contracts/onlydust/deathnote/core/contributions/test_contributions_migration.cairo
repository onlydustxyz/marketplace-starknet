%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from onlydust.deathnote.core.contributions.contributions_migration import migrate
from onlydust.deathnote.core.contributions.library import (
    contributions,
    Contribution,
    Status,
    Role,
    past_contributions_,
)

const ADMIN = 'admin'
const FEEDER = 'feeder'

@view
func test_migration_unassigned{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_1 = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (contribution1) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_1)
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}
    
    migrate()
    
    %{ expect_events(
        # Original events
        {"name": "ContributionCreated", "data": {"project_id": 'MyProject', "contribution_id": ids.contribution_id, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 123, "contributor_id": {"low": 1, "high": 0}}},
        {"name": "ContributionUnassigned", "data": {"contribution_id": 123}},
        # Migration events
        {"name": "ContributionCreated", "data": {"project_id": 'MyProject', "contribution_id": 123, "gate": 0}},
    )%}

    return()
end

@view
func test_migration_reassigned{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_1 = Uint256(1, 0)
    let contributor_2 = Uint256(2, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (contribution1) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_1)
    contributions.unassign_contributor_from_contribution(contribution_id)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_2)
    %{ stop_prank() %}
    
    migrate()

    %{ expect_events(
        # Original events
        {"name": "ContributionCreated", "data": {"project_id": 'MyProject', "contribution_id": ids.contribution_id, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 123, "contributor_id": {"low": 1, "high": 0}}},
        {"name": "ContributionUnassigned", "data": {"contribution_id": 123}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 123, "contributor_id": {"low": 2, "high": 0}}},
        # Migration events
        {"name": "ContributionCreated", "data": {"project_id": 'MyProject', "contribution_id": 123, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 123, "contributor_id": {"low": 2, "high": 0}}},
    )%}

    return()
end

@view
func test_migration_validated{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_1 = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (contribution1) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_1)
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}
    
    migrate()

    %{ expect_events(
        # Original events
        {"name": "ContributionCreated", "data": {"project_id": 'MyProject', "contribution_id": ids.contribution_id, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 123, "contributor_id": {"low": 1, "high": 0}}},
        {"name": "ContributionValidated", "data": {"contribution_id": 123}},
        # Migration events
        {"name": "ContributionCreated", "data": {"project_id": 'MyProject', "contribution_id": 123, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 123, "contributor_id": {"low": 2, "high": 0}}},
        {"name": "ContributionValidated", "data": {"contribution_id": 123}},
    )%}

    return()
end


namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        contributions.initialize(ADMIN)
        %{ stop_prank = start_prank(ids.ADMIN) %}
        contributions.grant_feeder_role(FEEDER)
        %{ stop_prank() %}
        return ()
    end
end