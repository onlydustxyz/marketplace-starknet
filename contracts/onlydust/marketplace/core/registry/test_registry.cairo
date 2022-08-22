%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.core.registry.library import registry, Role
from onlydust.marketplace.test.libraries.user import assert_user_that

const PROFILE = 'marketplace profile'
const REGISTERER = 'register'
const CONTRIBUTOR = 'Antho'
const GITHUB_USER = 'github_user'
const ADMIN = 'onlydust'

#
# Fixtures
#
namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        %{ stop_prank = start_prank(ids.ADMIN) %}
        registry.initialize(ADMIN)
        registry.grant_registerer_role(REGISTERER)
        registry.set_profile_contract(PROFILE)
        %{ stop_prank() %}

        return ()
    end
end

@view
func test_admin_can_change_the_profile_contract{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let (profile_contract) = registry.profile_contract()
    assert PROFILE = profile_contract

    const NEW_PROFILE = 'NEW_PROFILE'
    %{ stop_prank = start_prank(ids.ADMIN) %}
    registry.set_profile_contract(NEW_PROFILE)
    %{ stop_prank() %}

    let (profile_contract) = registry.profile_contract()
    assert NEW_PROFILE = profile_contract

    return ()
end

@view
func test_anyone_cannot_set_profile_contract{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Registry: ADMIN role required") %}
    registry.set_profile_contract(PROFILE)
    return ()
end

@view
func test_anyone_cannot_register_a_user{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Registry: REGISTERER role required") %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    return ()
end

@view
func test_getting_contributor_id_of_unregistered_user_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Registry: Unregistered user") %}
    registry.get_user_information(CONTRIBUTOR)

    return ()
end

@view
func test_registering_a_user_without_profile_contract_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    %{ stop_prank = start_prank(ids.ADMIN) %}
    registry.initialize(ADMIN)
    registry.grant_registerer_role(REGISTERER)
    %{
        stop_prank()
        stop_prank = start_prank(ids.REGISTERER)
        expect_revert(error_message="Registry: Missing Profile contract")
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end

@view
func test_register_can_register_a_github_identifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    tempvar CONTRIBUTOR_ID = Uint256(0, 0)

    %{
        stop_prank = start_prank(ids.REGISTERER)
        mock_call(ids.PROFILE, 'mint', [0, 0])
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    %{
        stop_prank() 
        expect_events({"name": "GithubIdentifierRegistered", "data": [ids.PROFILE, ids.CONTRIBUTOR_ID.low, ids.CONTRIBUTOR_ID.high, ids.GITHUB_USER]})
    %}

    let (user) = registry.get_user_information_from_github_identifier(GITHUB_USER)

    local syscall_ptr : felt* = syscall_ptr

    with user:
        assert_user_that.profile_contract_is(PROFILE)
        assert_user_that.contributor_id_is(CONTRIBUTOR_ID)
        assert_user_that.github_identifier_is(GITHUB_USER)
    end

    return ()
end

@view
func test_register_can_unregister_a_github_identifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.REGISTERER)
        mock_call(ids.PROFILE, 'mint', [0, 0])
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    registry.unregister_github_identifier(CONTRIBUTOR, GITHUB_USER)

    tempvar CONTRIBUTOR_ID = Uint256(0, 0)
    %{
        stop_prank() 
        expect_events(
            {"name": "GithubIdentifierRegistered", "data": [ids.PROFILE, ids.CONTRIBUTOR_ID.low, ids.CONTRIBUTOR_ID.high, ids.GITHUB_USER]}, 
            {"name": "GithubIdentifierUnregistered", "data": [ids.PROFILE, ids.CONTRIBUTOR_ID.low, ids.CONTRIBUTOR_ID.high, ids.GITHUB_USER]}
        )
        expect_revert(error_message="Registry: Unregistered user")
    %}
    registry.get_user_information_from_github_identifier(GITHUB_USER)

    return ()
end

@view
func test_register_cannot_unregister_a_github_identifier_from_wrong_user{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const ANYONE = 'anyone'

    %{
        stop_prank = start_prank(ids.REGISTERER)
        mock_call(ids.PROFILE, 'mint', [0, 0])
        expect_revert(error_message='Registry: The address does not match the github identifier provided')
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    registry.unregister_github_identifier(ANYONE, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_unregister_a_github_identifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const ANYONE = 'anyone'

    %{
        stop_prank = start_prank(ids.REGISTERER)
        mock_call(ids.PROFILE, 'mint', [0, 0])
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    %{
        stop_prank = start_prank(ids.ANYONE)
        expect_revert(error_message='Registry: REGISTERER role required')
    %}
    registry.unregister_github_identifier(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end

@view
func test_prevent_double_registration_of_github_identifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const ANYONE = 'anyone'

    %{
        stop_prank = start_prank(ids.REGISTERER)
        mock_call(ids.PROFILE, 'mint', [0, 0])
        expect_revert(error_message='Registry: Github identifier already registered')
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
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
        expect_revert(error_message="Registry: Cannot self renounce to ADMIN role")
    %}
    registry.revoke_admin_role(ADMIN)

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
    registry.grant_admin_role(NEW_ADMIN)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.NEW_ADMIN) %}
    registry.revoke_admin_role(ADMIN)
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
    registry.grant_admin_role(CONTRIBUTOR)

    return ()
end

@view
func test_anyone_cannot_revoke_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    registry.revoke_admin_role(ADMIN)

    return ()
end

@view
func test_admin_can_grant_and_revoke_roles{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    registry.grant_registerer_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        mock_call(ids.PROFILE, 'mint', [0, 0])
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN) %}
    registry.revoke_registerer_role(RANDOM_ADDRESS)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.REGISTERER, ids.RANDOM_ADDRESS, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.REGISTERER, ids.RANDOM_ADDRESS, ids.ADMIN]}
        )
    %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        expect_revert(error_message='Registry: REGISTERER role required')
    %}
    registry.register_github_identifier(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end
