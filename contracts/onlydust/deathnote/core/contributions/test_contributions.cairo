%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.library import contributions, Contribution, Status, Role
from onlydust.deathnote.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin'
const FEEDER = 'feeder'
const REGISTRY = 'registry'

@view
func test_new_contribution_can_be_added{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution1 = Contribution(123, 456, Status.OPEN)
    let contribution2 = Contribution(124, 456, Status.OPEN)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution1)
    contributions.new_contribution(contribution1)  # adding twice the same to test update
    contributions.new_contribution(contribution2)
    %{ stop_prank() %}

    let (count, contribs) = contributions.all_contributions()

    assert 2 = count
    assert contribution2 = contribs[0]
    assert contribution1 = contribs[1]

    return ()
end

@view
func test_feeder_can_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contribution = Contribution(contribution_id, 456, Status.OPEN)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.new_contribution(contribution)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.ASSIGNED)
    end

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
    contributions.new_contribution(Contribution(123, 456, 10))
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
        expect_revert(error_message="Contributions: Invalid status ({contribution.status}), expected (0)")
    %}
    contributions.new_contribution(Contribution(123, 456, Status.COMPLETED))
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
    contributions.new_contribution(Contribution(0, 456, Status.OPEN))
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
    contributions.new_contribution(Contribution(123, 0, Status.OPEN))
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_add_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Contributions: FEEDER role required") %}
    contributions.new_contribution(Contribution(123, 456, Status.OPEN))

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
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.grant_feeder_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.RANDOM_ADDRESS) %}
    contributions.new_contribution(Contribution(123, 456, Status.OPEN))
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
    contributions.new_contribution(Contribution(123, 456, Status.OPEN))
    %{ stop_prank() %}

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
