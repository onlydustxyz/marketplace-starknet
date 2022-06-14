%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.github.library import github, Contribution, Status, Role
from onlydust.deathnote.test.libraries.contributions.github import assert_github_contribution_that

const ADMIN = 'admin'
const FEEDER = 'feeder'
const REGISTRY = 'registry'

@view
func test_github_contribution_can_be_created{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let TOKEN_ID = Uint256(12, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.MERGED)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    github.add_contribution(TOKEN_ID, contribution)
    %{ stop_prank() %}

    let (contribution_count) = github.contribution_count(TOKEN_ID)
    assert 1 = contribution_count

    let (contribution) = github.contribution(TOKEN_ID, 0)
    with contribution:
        assert_github_contribution_that.repo_owner_is('onlydust')
        assert_github_contribution_that.repo_name_is('starkonquest')
        assert_github_contribution_that.pr_id_is(23)
        assert_github_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

@view
func test_github_contribution_can_be_created_from_github_handle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    let GITHUB_USER = 'user123'
    local TOKEN_ID : Uint256 = Uint256(12, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.MERGED)

    %{
        stop_prank = start_prank(ids.FEEDER)
        mock_call(ids.REGISTRY, 'get_user_information_from_github_handle', [0, ids.TOKEN_ID.low, ids.TOKEN_ID.high, ids.GITHUB_USER])
    %}
    github.add_contribution_from_handle(GITHUB_USER, contribution)
    %{ stop_prank() %}

    let (contribution_count) = github.contribution_count(TOKEN_ID)
    assert 1 = contribution_count

    let (contribution) = github.contribution(TOKEN_ID, 0)
    with contribution:
        assert_github_contribution_that.repo_owner_is('onlydust')
        assert_github_contribution_that.repo_name_is('starkonquest')
        assert_github_contribution_that.pr_id_is(23)
        assert_github_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

@view
func test_adding_github_contribution_from_handle_wihtout_registry_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    let GITHUB_USER = 'user123'
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.MERGED)

    %{ expect_revert(error_message="Github: Registry cannot be 0") %}
    github.add_contribution_from_handle(GITHUB_USER, contribution)

    return ()
end

@view
func test_github_contribution_creation_with_invalid_status_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let TOKEN_ID = Uint256(23, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, 10)

    %{ expect_revert(error_message="Github: Invalid PR status (10)") %}
    github.add_contribution(TOKEN_ID, contribution)

    return ()
end

@view
func test_github_contribution_creation_with_no_status_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let TOKEN_ID = Uint256(23, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.NONE)

    %{ expect_revert(error_message="Github: Invalid PR status (0)") %}
    github.add_contribution(TOKEN_ID, contribution)

    return ()
end

@view
func test_getting_contribution_from_invalid_id_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let TOKEN_ID = Uint256(23, 0)
    const INVALID_CONTRIBUTION_ID = 10

    %{ expect_revert(error_message="Github: Invalid contribution id (10)") %}
    github.contribution(TOKEN_ID, INVALID_CONTRIBUTION_ID)

    return ()
end

@view
func test_github_contribution_can_be_updated{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let TOKEN_ID = Uint256(12, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    github.add_contribution(TOKEN_ID, Contribution('onlydust', 'starkonquest', 23, Status.REVIEW))
    github.add_contribution(TOKEN_ID, Contribution('onlydust', 'starkonquest', 23, Status.MERGED))
    %{ stop_prank() %}

    let (contribution_count) = github.contribution_count(TOKEN_ID)
    assert 1 = contribution_count

    let (contribution) = github.contribution(TOKEN_ID, 0)
    with contribution:
        assert_github_contribution_that.repo_owner_is('onlydust')
        assert_github_contribution_that.repo_name_is('starkonquest')
        assert_github_contribution_that.pr_id_is(23)
        assert_github_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

@view
func test_github_contribution_cannot_update_owner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ stop_prank = start_prank(ids.FEEDER) %}
    github.add_contribution(
        Uint256(12, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )

    %{ expect_revert(error_message="Github: Cannot change the owner of a given contribution") %}
    github.add_contribution(
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

    %{ expect_revert(error_message="Github: FEEDER role required") %}
    github.add_contribution(
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
        expect_revert(error_message="Github: Cannot self renounce to ADMIN role")
    %}
    github.revoke_admin_role(ADMIN)

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
    github.grant_admin_role(NEW_ADMIN)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.NEW_ADMIN) %}
    github.revoke_admin_role(ADMIN)
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
    github.grant_admin_role(FEEDER)

    return ()
end

@view
func test_anyone_cannot_revoke_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    github.revoke_admin_role(ADMIN)

    return ()
end

@view
func test_admin_can_grant_and_revoke_roles{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    github.grant_feeder_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.RANDOM_ADDRESS) %}
    github.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN) %}
    github.revoke_feeder_role(RANDOM_ADDRESS)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.FEEDER, ids.RANDOM_ADDRESS, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.FEEDER, ids.RANDOM_ADDRESS, ids.ADMIN]}
        )
    %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        expect_revert(error_message='Github: FEEDER role required')
    %}
    github.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_set_registry_contract{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Github: ADMIN role required") %}
    github.set_registry_contract(REGISTRY)

    return ()
end

namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        github.initialize(ADMIN)
        %{ stop_prank = start_prank(ids.ADMIN) %}
        github.grant_feeder_role(FEEDER)
        github.set_registry_contract(REGISTRY)
        %{ stop_prank() %}
        return ()
    end
end
