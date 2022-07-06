%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.library import (
    contributions,
    Contribution,
    Status,
    Role,
    past_contributions_,
)  # TODO: Create a proper getter for past_contributions_
from onlydust.deathnote.test.libraries.contributions import (
    assert_contribution_that,
    contribution_access,
)

const ADMIN = 'admin'
const FEEDER = 'feeder'
const REGISTRY = 'registry'

@view
func test_new_contribution_can_be_added{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    let (local contribution1) = contribution_access.create(123, 456)
    let (contribution2) = contribution_access.create(124, 456)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution1)
    contributions.new_contribution(contribution1)  # adding twice the same to test update
    contributions.new_contribution(contribution2)
    %{ stop_prank() %}

    let (count, contribs) = contributions.all_contributions()

    assert 2 = count

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(contribution1.id)
        assert_contribution_that.project_id_is(contribution1.project_id)
        assert_contribution_that.status_is(Status.OPEN)
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(contribution2.id)
        assert_contribution_that.project_id_is(contribution2.project_id)
        assert_contribution_that.status_is(Status.OPEN)
    end

    return ()
end

@view
func test_feeder_can_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(contributor_id)
    end

    return ()
end

@view
func test_anyone_cannot_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: FEEDER role required")
    %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)

    return ()
end

@view
func test_cannot_assign_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{
        stop_prank = start_prank(ids.FEEDER) 
        expect_revert(error_message="Contributions: Contribution does not exist")
    %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_assign_twice_a_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ expect_revert(error_message="Contributions: Contribution is not OPEN") %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_assign_contribution_to_non_eligible_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create_with_gate(contribution_id, 456, 3)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    %{ expect_revert(error_message="Contributions: Contributor is not eligible") %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_can_assign_gated_contribution_eligible_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    const gated_contribution_id = 124
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    # Create a non-gated contribution
    let (contribution) = contribution_access.create(contribution_id, 456)
    contributions.new_contribution(contribution)

    # Create a gated contribution
    let (contribution) = contribution_access.create_with_gate(gated_contribution_id, 456, 1)
    contributions.new_contribution(contribution)

    # Assign and validate the non-gated contribution
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.validate_contribution(contribution_id)

    # Assign and validate the gated contribution
    contributions.assign_contributor_to_contribution(gated_contribution_id, contributor_id)
    contributions.validate_contribution(gated_contribution_id)
    %{ stop_prank() %}

    let (past_contributions) = past_contributions_.read(contributor_id)
    assert 2 = past_contributions

    return ()
end

@view
func test_contribution_creation_with_invalid_status_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid contribution status")
    %}
    contributions.new_contribution(Contribution(123, 456, 10, Uint256(0, 0), 1))
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_status_not_open_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Contribution is not OPEN")
    %}
    contributions.new_contribution(Contribution(123, 456, Status.COMPLETED, Uint256(1, 0), 1))
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_invalid_id_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid contribution ID")
    %}
    let (contribution) = contribution_access.create(0, 456)
    contributions.new_contribution(contribution)
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_invalid_project_id_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid project ID")
    %}
    let (contribution) = contribution_access.create(123, 0)
    contributions.new_contribution(contribution)
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_contributor_id_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid contributor ID")
    %}
    contributions.new_contribution(Contribution(123, 456, Status.OPEN, Uint256(1, 0), 1))
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_invalid_contribution_count_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Contribution is not OPEN")
    %}
    contributions.new_contribution(Contribution(123, 456, Status.COMPLETED, Uint256(1, 0), 1))
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_add_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Contributions: FEEDER role required") %}
    let (contribution) = contribution_access.create(123, 456)
    contributions.new_contribution(contribution)

    return ()
end

@view
func test_feeder_can_unassign_contribution_from_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.OPEN)
        assert_contribution_that.contributor_is(Uint256(0, 0))
    end

    return ()
end

@view
func test_anyone_cannot_unassign_contribution_from_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: FEEDER role required")
    %}
    contributions.unassign_contributor_from_contribution(contribution_id)

    return ()
end

@view
func test_cannot_unassign_from_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{
        stop_prank = start_prank(ids.FEEDER) 
        expect_revert(error_message="Contributions: Contribution does not exist")
    %}
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_unassign_contribution_if_not_assigned{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_feeder_can_validate_assigned_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    return ()
end

@view
func test_anyone_cannot_validate_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: FEEDER role required")
    %}
    contributions.validate_contribution(contribution_id)

    return ()
end

@view
func test_cannot_validate_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123

    %{
        stop_prank = start_prank(ids.FEEDER) 
        expect_revert(error_message="Contributions: Contribution does not exist")
    %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_validate_contribution_if_not_assigned{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let (contribution) = contribution_access.create(contribution_id, 456)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_admin_cannot_revoke_himself{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.ADMIN)
        expect_revert(error_message="Contributions: Cannot self renounce to ADMIN role")
    %}
    contributions.revoke_admin_role(ADMIN)

    %{ stop_prank() %}

    return ()
end

@view
func test_admin_can_transfer_ownership{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const NEW_ADMIN = 'new_admin'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.grant_admin_role(NEW_ADMIN)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.NEW_ADMIN) %}
    contributions.revoke_admin_role(ADMIN)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.ADMIN, ids.NEW_ADMIN, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.ADMIN, ids.ADMIN, ids.NEW_ADMIN]}
        )
    %}

    return ()
end

@view
func test_anyone_cannot_grant_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    contributions.grant_admin_role(FEEDER)

    return ()
end

@view
func test_anyone_cannot_revoke_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    contributions.revoke_admin_role(ADMIN)

    return ()
end

@view
func test_admin_can_grant_and_revoke_roles{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.grant_feeder_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.RANDOM_ADDRESS) %}
    let (local contribution) = contribution_access.create(123, 456)
    contributions.new_contribution(contribution)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.revoke_feeder_role(RANDOM_ADDRESS)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.FEEDER, ids.RANDOM_ADDRESS, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.FEEDER, ids.RANDOM_ADDRESS, ids.ADMIN]}
        )
    %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        expect_revert(error_message='Contributions: FEEDER role required')
    %}
    contributions.new_contribution(contribution)
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_can_list_open_contributions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    %{ stop_prank = start_prank(ids.FEEDER) %}
    const contribution1_id = 123
    let (contribution1) = contribution_access.create(contribution1_id, 456)
    contributions.new_contribution(contribution1)
    contributions.assign_contributor_to_contribution(contribution1_id, Uint256(1, 0))

    const contribution2_id = 124
    let (local contribution2) = contribution_access.create(contribution2_id, 456)
    contributions.new_contribution(contribution2)
    %{ stop_prank() %}

    let (contribs_len, contribs) = contributions.all_open_contributions()
    assert 1 = contribs_len
    assert contribution2 = contribs[0]

    return ()
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
