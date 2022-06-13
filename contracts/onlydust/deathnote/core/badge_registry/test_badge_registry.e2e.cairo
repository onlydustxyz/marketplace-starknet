%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.badge_registry import IBadgeRegistry, UserInformation
from onlydust.deathnote.test.libraries.user import assert_user_that

const ADMIN = 'admin'
const BADGE = 'badge'
const CONTRIBUTOR = 'contributor'
const GITHUB_HANDLE = 'github_user'

#
# Tests
#
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tempvar badge_registry
    %{
        context.badge_registry = deploy_contract("./contracts/onlydust/deathnote/core/badge_registry/badge_registry.cairo", [ids.ADMIN]).contract_address 
        ids.badge_registry = context.badge_registry
        stop_prank = start_prank(ids.ADMIN, ids.badge_registry)
    %}
    IBadgeRegistry.set_badge_contract(badge_registry, BADGE)
    %{ stop_prank() %}

    return ()
end

@view
func test_badge_registry_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (badge_registry) = badge_registry_access.deployed()

    with badge_registry:
        %{ mock_call(ids.BADGE, 'mint', [0, 0]) %}
        let (user) = badge_registry_access.register_github_handle(CONTRIBUTOR, GITHUB_HANDLE)
    end

    with user:
        assert_user_that.badge_contract_is(BADGE)
        assert_user_that.token_id_is(Uint256(0, 0))
        assert_user_that.github_handle_is(GITHUB_HANDLE)
    end

    with badge_registry:
        let (user) = badge_registry_access.unregister_github_handle(CONTRIBUTOR, GITHUB_HANDLE)
    end

    with user:
        assert_user_that.badge_contract_is(BADGE)
        assert_user_that.token_id_is(Uint256(0, 0))
        assert_user_that.github_handle_is(0)
    end

    return ()
end

#
# Libraries
#
namespace badge_registry_access:
    func deployed() -> (badge_registry : felt):
        tempvar badge_registry
        %{ ids.badge_registry = context.badge_registry %}
        return (badge_registry)
    end

    func register_github_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, badge_registry : felt
    }(contributor : felt, handle : felt) -> (user : UserInformation):
        %{ stop_prank = start_prank(ids.ADMIN, ids.badge_registry) %}
        IBadgeRegistry.register_github_handle(badge_registry, contributor, handle)
        %{ stop_prank() %}

        let (user) = IBadgeRegistry.get_user_information_from_github_handle(badge_registry, handle)
        return (user)
    end

    func unregister_github_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, badge_registry : felt
    }(contributor : felt, handle : felt) -> (user : UserInformation):
        %{ stop_prank = start_prank(ids.ADMIN, ids.badge_registry) %}
        IBadgeRegistry.unregister_github_handle(badge_registry, contributor, handle)
        %{ stop_prank() %}

        let (user) = IBadgeRegistry.get_user_information(badge_registry, contributor)
        return (user)
    end
end
