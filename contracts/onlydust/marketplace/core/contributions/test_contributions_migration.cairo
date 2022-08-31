%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from onlydust.marketplace.core.contributions.contributions_migration import migrate, contributions_, contribution_count_, indexed_contribution_ids_ 
from onlydust.marketplace.core.contributions.library import (
    contributions,
    DeprecatedContribution,
    DeprecatedStatus,
    Status,
    contribution_access,
    Contribution,
    ContributionId,
)
from onlydust.marketplace.core.contributions.access_control import access_control


const ADMIN = 'admin'
const FEEDER = 'feeder'

@view
func test_migration_open{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    let project_id = 'MyProject'
    let old_id = project_id * 1000000 + 1
    let old_contribution = DeprecatedContribution(
        old_id,
        project_id,
        DeprecatedStatus.OPEN,
        Uint256(0, 0),
        1,
        1        
    )

    contributions_.write(old_id, old_contribution)
    indexed_contribution_ids_.write(0, old_id)
    contribution_count_.write(1)
    
    migrate()
    
    let expected_id = ContributionId(1)
    let (new_contribution) = contribution_access.build(expected_id)
    assert new_contribution = Contribution(expected_id, project_id, Status.OPEN, 1, Uint256(0, 0))
    
    %{ expect_events(
        {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.project_id, "issue_number" : 1, "gate": 1}},
    )%}

    return()
end

@view
func test_migration_assigned{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    let project_id = 'MyProject'
    let old_id = project_id * 1000000 + 1
    let old_contribution = DeprecatedContribution(
        old_id,
        project_id,
        DeprecatedStatus.ASSIGNED,
        Uint256(1, 0),
        0,
        0        
    )

    contributions_.write(old_id, old_contribution)
    indexed_contribution_ids_.write(0, old_id)
    contribution_count_.write(1)

    migrate()

    let (new_contribution) = contribution_access.build(ContributionId(1))
    assert new_contribution = Contribution(ContributionId(1), project_id, Status.ASSIGNED, 0, Uint256(1, 0))

    %{ expect_events(
        {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.project_id, "issue_number" : 1, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": 1, "high": 0}}},
    )%}

    return()
end

@view
func test_migration_validated{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    let project_id = 'MyProject'
    let old_id = project_id * 1000000 + 1
    let old_contribution = DeprecatedContribution(
        old_id,
        project_id,
        DeprecatedStatus.COMPLETED,
        Uint256(1, 0),
        0,
        0        
    )

    contributions_.write(old_id, old_contribution)
    indexed_contribution_ids_.write(0, old_id)
    contribution_count_.write(1)
    
    migrate()

    let (new_contribution) = contribution_access.build(ContributionId(1))
    assert new_contribution = Contribution(ContributionId(1), project_id, Status.COMPLETED, 0, Uint256(1, 0))

    %{ expect_events(
        {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.project_id, "issue_number" : 1, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": 1, "high": 0}}},
        {"name": "ContributionValidated", "data": {"contribution_id": 1}},
    )%}

    return()
end

@view
func test_migration_validated_multiple{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    let project_id = 'MyProject'
    let old_id = project_id * 1000000 + 1
    let old_contribution = DeprecatedContribution(
        old_id,
        project_id,
        DeprecatedStatus.COMPLETED,
        Uint256(1, 0),
        0,
        0        
    )

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions_.write(old_id, old_contribution)
    indexed_contribution_ids_.write(0, old_id)
    contribution_count_.write(1)
    %{ stop_prank() %}

    let old_id = project_id * 1000000 + 2
    let old_contribution = DeprecatedContribution(
        old_id,
        project_id,
        DeprecatedStatus.COMPLETED,
        Uint256(1, 0),
        0,
        0        
    )

    contributions_.write(old_id, old_contribution)
    indexed_contribution_ids_.write(1, old_id)
    contribution_count_.write(2)
    
    migrate()
    
    let (new_contribution) = contribution_access.build(ContributionId(1))
    assert new_contribution = Contribution(ContributionId(1), project_id, Status.COMPLETED, 0, Uint256(1, 0))
    
    let (new_contribution) = contribution_access.build(ContributionId(2))
    assert new_contribution = Contribution(ContributionId(2), project_id, Status.COMPLETED, 0, Uint256(1, 0))

    %{ expect_events(
        {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.project_id, "issue_number" : 1, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": 1, "high": 0}}},
        {"name": "ContributionValidated", "data": {"contribution_id": 1}},
        {"name": "ContributionCreated", "data": {"contribution_id": 2, "project_id": ids.project_id, "issue_number" : 2, "gate": 0}},
        {"name": "ContributionAssigned", "data": {"contribution_id": 2, "contributor_id": {"low": 1, "high": 0}}},
        {"name": "ContributionValidated", "data": {"contribution_id": 2}},
    )%}

    return()
end


namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        contributions.initialize(ADMIN)

        return ()
    end
end