%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.badge.library import badge

const ADMIN = 'onlydust_admin'
const REGISTRY = 'registry'
const CONTRIBUTOR = 'Antho'

#
# Fixtures
#
namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        %{ stop_prank = start_prank(ids.ADMIN) %}
        badge.initialize(ADMIN)
        badge.grant_minter_role(REGISTRY)
        %{ stop_prank() %}

        return ()
    end
end

#
# Tests
#
@view
func test_badge_has_a_name_and_symbol{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    assert_that.badge_name_is('Death Note Badge')
    assert_that.badge_symbol_is('DNB')

    return ()
end

@view
func test_badge_can_be_minted{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    %{ stop_prank = start_prank(ids.REGISTRY) %}
    let (tokenId) = badge.mint(CONTRIBUTOR)
    %{ stop_prank() %}

    let (owner) = badge.ownerOf(tokenId)

    assert_that.badge_owner_is(tokenId, CONTRIBUTOR)

    return ()
end

@view
func test_badge_cannot_be_minted_by_anyone{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Badge: MINTER role required") %}
    badge.mint(CONTRIBUTOR)

    return ()
end

@view
func test_admin_cannot_revoke_himself{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.ADMIN)
        expect_revert(error_message="Badge: Cannot self renounce to ADMIN role")
    %}
    badge.revoke_admin_role(ADMIN)

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
    badge.grant_admin_role(NEW_ADMIN)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.NEW_ADMIN) %}
    badge.revoke_admin_role(ADMIN)
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_grant_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    badge.grant_admin_role(CONTRIBUTOR)

    return ()
end

@view
func test_anyone_cannot_revoke_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    badge.revoke_admin_role(ADMIN)

    return ()
end

@view
func test_admin_can_grant_and_revoke_roles{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    badge.grant_minter_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.RANDOM_ADDRESS) %}
    badge.mint(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN) %}
    badge.revoke_minter_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        expect_revert(error_message='Badge: MINTER role required')
    %}
    badge.mint(RANDOM_ADDRESS)
    %{ stop_prank() %}

    return ()
end

#
# Helpers
#
namespace assert_that:
    func badge_name_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected : felt
    ):
        alloc_locals
        let (local actual) = badge.name()

        with_attr error_message("Invalid name: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func badge_symbol_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected : felt
    ):
        alloc_locals
        let (local actual) = badge.symbol()

        with_attr error_message("Invalid symbol: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func badge_owner_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256, expected : felt
    ):
        alloc_locals
        let (local actual) = badge.ownerOf(tokenId)

        with_attr error_message("Invalid owner: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end
