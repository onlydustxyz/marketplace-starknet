%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.core.profile.library import profile, Role

const ADMIN = 'onlydust_admin'
const REGISTRY = 'registry'
const CONTRIBUTOR = 'Antho'

#
# Fixtures
#
namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        %{ stop_prank = start_prank(ids.ADMIN) %}
        profile.initialize(ADMIN)
        profile.grant_minter_role(REGISTRY)
        %{
            stop_prank() 
            expect_events(
                {"name": "RoleGranted", "data": [ids.Role.ADMIN, ids.ADMIN, ids.ADMIN]},
                {"name": "RoleGranted", "data": [ids.Role.MINTER, ids.REGISTRY, ids.ADMIN]}
            )
        %}

        return ()
    end
end

#
# Tests
#
@view
func test_profile_has_a_name_and_symbol{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    assert_that.profile_name_is('Death Note Profile')
    assert_that.profile_symbol_is('DNP')

    return ()
end

@view
func test_profile_can_be_minted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ):
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.REGISTRY) %}
    let (local tokenId) = profile.mint(CONTRIBUTOR)
    %{ stop_prank() %}

    let (owner) = profile.ownerOf(tokenId)

    assert_that.profile_owner_is(tokenId, CONTRIBUTOR)

    %{ expect_events({"name": "Transfer", "data": [0, ids.CONTRIBUTOR, ids.tokenId.low, ids.tokenId.high]}) %}

    return ()
end

@view
func test_minting_twice_always_returns_the_same_token_id{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.REGISTRY) %}
    let (local tokenId1) = profile.mint(CONTRIBUTOR)
    let (tokenId2) = profile.mint(CONTRIBUTOR)
    %{ stop_prank() %}

    assert tokenId1 = tokenId2

    %{ expect_events({"name": "Transfer", "data": [0, ids.CONTRIBUTOR, ids.tokenId1.low, ids.tokenId1.high]}) %}

    return ()
end

@view
func test_profile_cannot_be_minted_by_anyone{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="profile: MINTER role required") %}
    profile.mint(CONTRIBUTOR)

    return ()
end

@view
func test_admin_cannot_revoke_himself{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.ADMIN)
        expect_revert(error_message="profile: Cannot self renounce to ADMIN role")
    %}
    profile.revoke_admin_role(ADMIN)

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
    profile.grant_admin_role(NEW_ADMIN)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.NEW_ADMIN) %}
    profile.revoke_admin_role(ADMIN)
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
    profile.grant_admin_role(CONTRIBUTOR)

    return ()
end

@view
func test_anyone_cannot_revoke_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    profile.revoke_admin_role(ADMIN)

    return ()
end

@view
func test_admin_can_grant_and_revoke_roles{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    profile.grant_minter_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.RANDOM_ADDRESS) %}
    profile.mint(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN) %}
    profile.revoke_minter_role(RANDOM_ADDRESS)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.MINTER, ids.RANDOM_ADDRESS, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.MINTER, ids.RANDOM_ADDRESS, ids.ADMIN]}
        )
    %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        expect_revert(error_message='profile: MINTER role required')
    %}
    profile.mint(RANDOM_ADDRESS)
    %{ stop_prank() %}

    return ()
end

#
# Helpers
#
namespace assert_that:
    func profile_name_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected : felt
    ):
        alloc_locals
        let (local actual) = profile.name()

        with_attr error_message("Invalid name: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func profile_symbol_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected : felt
    ):
        alloc_locals
        let (local actual) = profile.symbol()

        with_attr error_message("Invalid symbol: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func profile_owner_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256, expected : felt
    ):
        alloc_locals
        let (local actual) = profile.ownerOf(tokenId)

        with_attr error_message("Invalid owner: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end
