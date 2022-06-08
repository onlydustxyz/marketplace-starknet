%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.badge import IBadge

const ADMIN = 'admin'
const REGISTRY = 'registry'
const CONTRIBUTOR = 'contributor'

#
# Tests
#
@view
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    tempvar badge_contract
    %{
        context.badge_contract = deploy_contract("./contracts/onlydust/deathnote/core/badge/badge.cairo", [ids.ADMIN]).contract_address
        ids.badge_contract = context.badge_contract
        stop_prank = start_prank(ids.ADMIN, ids.badge_contract)
    %}
    IBadge.grant_minter_role(badge_contract, REGISTRY)
    %{ stop_prank() %}

    return ()
end

@view
func test_badge_e2e{syscall_ptr : felt*, range_check_ptr}():
    let (badge) = badge_access.deployed()

    with badge:
        assert_that.name_is('Death Note Badge')
        assert_that.symbol_is('DNB')

        let (token_id) = badge_access.mint(CONTRIBUTOR)
        assert_that.owner_is(token_id, CONTRIBUTOR)
    end

    return ()
end

#
# Libraries
#
namespace badge_access:
    func deployed() -> (badge_contract : felt):
        tempvar badge_contract
        %{ ids.badge_contract = context.badge_contract %}
        return (badge_contract)
    end

    func mint{syscall_ptr : felt*, range_check_ptr, badge : felt}(contributor : felt) -> (
        token_id : Uint256
    ):
        %{ stop_prank = start_prank(ids.REGISTRY,  ids.badge) %}
        let (token_id) = IBadge.mint(badge, contributor)
        %{ stop_prank() %}
        return (token_id)
    end
end

namespace assert_that:
    func name_is{syscall_ptr : felt*, range_check_ptr, badge : felt}(expected : felt):
        alloc_locals
        let (local actual) = IBadge.name(badge)

        with_attr error_message("Invalid name: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func symbol_is{syscall_ptr : felt*, range_check_ptr, badge : felt}(expected : felt):
        alloc_locals
        let (local actual) = IBadge.symbol(badge)

        with_attr error_message("Invalid symbol: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func owner_is{syscall_ptr : felt*, range_check_ptr, badge : felt}(
        token_id : Uint256, expected : felt
    ):
        alloc_locals
        let (local actual) = IBadge.ownerOf(badge, token_id)

        with_attr error_message("Invalid owner: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end
