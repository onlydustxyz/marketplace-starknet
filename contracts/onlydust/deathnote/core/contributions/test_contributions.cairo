%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.library import contributions, Contribution, Status, Role
from onlydust.deathnote.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin'
const FEEDER = 'feeder'
const REGISTRY = 'registry'

@view
func test_contribution_can_be_added{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let CONTRIBUTOR_ID = Uint256(12, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.MERGED)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.add_contribution(CONTRIBUTOR_ID, contribution)
    %{ stop_prank() %}

    let (contribution_count) = contributions.contribution_count(CONTRIBUTOR_ID)
    assert 1 = contribution_count

    let (contribution) = contributions.contribution(CONTRIBUTOR_ID, 0)
    with contribution:
        assert_contribution_that.repo_owner_is('onlydust')
        assert_contribution_that.repo_name_is('starkonquest')
        assert_contribution_that.pr_id_is(23)
        assert_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

@view
func test_contribution_creation_with_invalid_status_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let CONTRIBUTOR_ID = Uint256(23, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, 10)

    %{ expect_revert(error_message="Contributions: Invalid PR status (10)") %}
    contributions.add_contribution(CONTRIBUTOR_ID, contribution)

    return ()
end

@view
func test_contribution_creation_with_no_status_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let CONTRIBUTOR_ID = Uint256(23, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.NONE)

    %{ expect_revert(error_message="Contributions: Invalid PR status (0)") %}
    contributions.add_contribution(CONTRIBUTOR_ID, contribution)

    return ()
end

@view
func test_getting_contribution_from_invalid_id_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let CONTRIBUTOR_ID = Uint256(23, 0)
    const INVALID_CONTRIBUTION_ID = 10

    %{ expect_revert(error_message="Contributions: Invalid contribution id (10)") %}
    contributions.contribution(CONTRIBUTOR_ID, INVALID_CONTRIBUTION_ID)

    return ()
end

@view
func test_contribution_can_be_updated{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let CONTRIBUTOR_ID = Uint256(12, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.add_contribution(CONTRIBUTOR_ID, Contribution('onlydust', 'starkonquest', 23, Status.REVIEW))
    contributions.add_contribution(CONTRIBUTOR_ID, Contribution('onlydust', 'starkonquest', 23, Status.MERGED))
    %{ stop_prank() %}

    let (contribution_count) = contributions.contribution_count(CONTRIBUTOR_ID)
    assert 1 = contribution_count

    let (contribution) = contributions.contribution(CONTRIBUTOR_ID, 0)
    with contribution:
        assert_contribution_that.repo_owner_is('onlydust')
        assert_contribution_that.repo_name_is('starkonquest')
        assert_contribution_that.pr_id_is(23)
        assert_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

@view
func test_contribution_cannot_update_owner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ stop_prank = start_prank(ids.FEEDER) %}
    contributions.add_contribution(
        Uint256(12, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )

    %{ expect_revert(error_message="Contributions: Cannot change the owner of a given contribution") %}
    contributions.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_add_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Contributions: FEEDER role required") %}
    contributions.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )

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
    contributions.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )
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
    contributions.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )
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
