%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.badge_registry.library import badge_registry
from onlydust.deathnote.test.libraries.user import assert_user_that

const BADGE = 'deathnote badge'
const CONTRIBUTOR = 'Antho'
const GITHUB_USER = 'github_user'
const OWNER = 'onlydust'

#
# Fixtures
#
namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        %{ stop_prank = start_prank(ids.OWNER) %}
        badge_registry.initialize(OWNER)
        badge_registry.set_badge_contract(BADGE)
        %{ stop_prank() %}

        return ()
    end
end

@view
func test_owner_can_change_the_badge_contract{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let (badge_contract) = badge_registry.badge_contract()
    assert BADGE = badge_contract

    const NEW_BADGE = 'new_badge'
    %{ stop_prank = start_prank(ids.OWNER) %}
    badge_registry.set_badge_contract(NEW_BADGE)
    %{ stop_prank() %}

    let (badge_contract) = badge_registry.badge_contract()
    assert NEW_BADGE = badge_contract

    return ()
end

@view
func test_anyone_cannot_set_badge_contract{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    badge_registry.set_badge_contract(BADGE)
    return ()
end

@view
func test_anyone_cannot_register_a_user{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    return ()
end

@view
func test_getting_token_id_of_unregistered_user_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Badge Registry: Unregistered user") %}
    badge_registry.get_user_information(CONTRIBUTOR)

    return ()
end

@view
func test_anyone_cannot_transfer_ownership{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    badge_registry.transfer_ownership(CONTRIBUTOR)
    return ()
end

@view
func test_owner_can_transfer_ownership{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let (current_owner) = badge_registry.owner()
    assert OWNER = current_owner

    const NEW_OWNER = 'new_owner'
    %{ stop_prank = start_prank(ids.OWNER) %}
    badge_registry.transfer_ownership(NEW_OWNER)
    %{ stop_prank() %}

    let (current_owner) = badge_registry.owner()
    assert NEW_OWNER = current_owner

    %{ expect_events({"name": "OwnershipTransferred", "data": [ids.OWNER, ids.NEW_OWNER]}) %}

    return ()
end

@view
func test_registering_a_user_without_badge_contract_should_revert{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    %{ expect_revert(error_message="Badge Registry: Missing Badge contract") %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)

    return ()
end

@view
func test_owner_can_register_a_github_handle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    tempvar TOKEN_ID = Uint256(0, 0)

    %{
        stop_prank = start_prank(ids.OWNER)
        mock_call(ids.BADGE, 'mint', [0, 0])
    %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    %{
        stop_prank() 
        expect_events({"name": "GithubHandleRegistered", "data": [ids.BADGE, ids.TOKEN_ID.low, ids.TOKEN_ID.high, ids.GITHUB_USER]})
    %}

    let (user) = badge_registry.get_user_information_from_github_handle(GITHUB_USER)

    local syscall_ptr : felt* = syscall_ptr

    with user:
        assert_user_that.badge_contract_is(BADGE)
        assert_user_that.token_id_is(TOKEN_ID)
        assert_user_that.github_handle_is(GITHUB_USER)
    end

    return ()
end

@view
func test_owner_can_unregister_a_github_handle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.OWNER)
        mock_call(ids.BADGE, 'mint', [0, 0])
    %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    badge_registry.unregister_github_handle(CONTRIBUTOR, GITHUB_USER)

    tempvar TOKEN_ID = Uint256(0, 0)
    %{
        stop_prank() 
        expect_events(
            {"name": "GithubHandleRegistered", "data": [ids.BADGE, ids.TOKEN_ID.low, ids.TOKEN_ID.high, ids.GITHUB_USER]}, 
            {"name": "GithubHandleUnregistered", "data": [ids.BADGE, ids.TOKEN_ID.low, ids.TOKEN_ID.high, ids.GITHUB_USER]}
        )
        expect_revert(error_message="Badge Registry: Unregistered user")
    %}
    badge_registry.get_user_information_from_github_handle(GITHUB_USER)

    return ()
end

@view
func test_owner_cannot_unregister_a_github_handle_from_wrong_user{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const ANYONE = 'anyone'

    %{
        stop_prank = start_prank(ids.OWNER)
        mock_call(ids.BADGE, 'mint', [0, 0])
        expect_revert(error_message='Badge Registry: The address does not match the github handle provided')
    %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    badge_registry.unregister_github_handle(ANYONE, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_unregister_a_github_handle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const ANYONE = 'anyone'

    %{
        stop_prank = start_prank(ids.OWNER)
        mock_call(ids.BADGE, 'mint', [0, 0])
    %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    %{
        stop_prank = start_prank(ids.ANYONE)
        expect_revert(error_message='Ownable: caller is not the owner')
    %}
    badge_registry.unregister_github_handle(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end

@view
func test_prevent_double_registration_of_github_handle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const ANYONE = 'anyone'

    %{
        stop_prank = start_prank(ids.OWNER)
        mock_call(ids.BADGE, 'mint', [0, 0])
        expect_revert(error_message='Badge Registry: Github handle already registered')
    %}
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    badge_registry.register_github_handle(CONTRIBUTOR, GITHUB_USER)
    %{ stop_prank() %}

    return ()
end
