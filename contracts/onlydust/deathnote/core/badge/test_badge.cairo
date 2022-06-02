%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.badge.library import badge

const OWNER = 42

#
# Fixtures
#
namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        badge.initialize(OWNER)
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

    assert_that.name_is('Death Note Badge')
    assert_that.symbol_is('DNB')

    return ()
end

@view
func test_badge_can_be_minted_by_owner{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const CONTRIBUTOR = 23
    %{ stop_prank = start_prank(ids.OWNER) %}
    let (tokenId) = badge.mint(CONTRIBUTOR)
    %{ stop_prank() %}

    let (owner) = badge.ownerOf(tokenId)

    assert_that.owner_is(tokenId, CONTRIBUTOR)

    return ()
end

@view
func test_badge_cannot_be_minted_by_anyone{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const CONTRIBUTOR = 23

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    badge.mint(CONTRIBUTOR)

    return ()
end

#
# Helpers
#
namespace assert_that:
    func name_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected : felt
    ):
        alloc_locals
        let (local actual) = badge.name()

        with_attr error_message("Invalid name: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func symbol_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        expected : felt
    ):
        alloc_locals
        let (local actual) = badge.symbol()

        with_attr error_message("Invalid symbol: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func owner_is{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
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
