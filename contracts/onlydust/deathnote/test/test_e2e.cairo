%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.badge_registry import IBadgeRegistry, UserInformation
from onlydust.deathnote.interfaces.contributions.github import IGithub
from onlydust.deathnote.interfaces.badge import IBadge
from onlydust.deathnote.core.contributions.github.library import Contribution, Status
from onlydust.deathnote.test.libraries.user import assert_user_that
from onlydust.deathnote.test.libraries.contributions.github import assert_github_contribution_that

const ADMIN = 'onlydust'
const GITHUB = 'GITHUB'
const CONTRIBUTOR = '0xdead'
const GITHUB_HANDLE = 'user123'

#
# Tests
#
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tempvar badge_registry
    tempvar badge_contract
    tempvar github_contract
    %{
        ids.badge_registry = deploy_contract("./contracts/onlydust/deathnote/core/badge_registry/badge_registry.cairo", [ids.ADMIN]).contract_address 
        ids.badge_contract = deploy_contract("./contracts/onlydust/deathnote/core/badge/badge.cairo", [ids.ADMIN]).contract_address 
        ids.github_contract = deploy_contract("./contracts/onlydust/deathnote/core/contributions/github/github.cairo", [ids.ADMIN]).contract_address 

        context.badge_registry = ids.badge_registry
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.badge_registry, ids.badge_contract] ] %}
    IBadgeRegistry.set_badge_contract(badge_registry, badge_contract)
    IBadge.grant_minter_role(badge_contract, badge_registry)
    IBadge.register_metadata_contract(badge_contract, GITHUB, github_contract)
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return ()
end

@view
func test_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (badge_registry) = badge_registry_access.deployed()

    with badge_registry:
        let (local user) = badge_registry_access.register_github_handle(CONTRIBUTOR, GITHUB_HANDLE)
    end

    with user:
        assert_user_that.github_handle_is(GITHUB_HANDLE)
    end

    let (github) = IBadge.metadata_contract(user.badge_contract, 'GITHUB')
    with github:
        github_access.add_contribution(
            user.token_id, Contribution('onlydust', 'starklings', 23, Status.OPEN)
        )
        github_access.add_contribution(
            user.token_id, Contribution('onlydust', 'starklings', 24, Status.OPEN)
        )
        let (contribution_count) = github_access.contribution_count(user.token_id)
        assert contribution_count = 2

        let (contribution) = github_access.contribution(user.token_id, 0)
    end

    with contribution:
        assert_github_contribution_that.repo_owner_is('onlydust')
        assert_github_contribution_that.repo_name_is('starklings')
        assert_github_contribution_that.pr_id_is(23)
        assert_github_contribution_that.pr_status_is(Status.OPEN)
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

        let (user) = IBadgeRegistry.get_user_information(badge_registry, contributor)
        return (user)
    end
end

namespace github_access:
    func deployed() -> (github_contract : felt):
        tempvar github_contract
        %{ ids.github_contract = context.github_contract %}
        return (github_contract)
    end

    func add_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, github : felt
    }(token_id : Uint256, contribution : Contribution):
        %{ stop_prank = start_prank(ids.ADMIN, ids.github) %}
        IGithub.add_contribution(github, token_id, contribution)
        %{ stop_prank() %}
        return ()
    end

    func contribution_count{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, github : felt
    }(token_id : Uint256) -> (contribution_count : felt):
        let (contribution_count) = IGithub.contribution_count(github, token_id)
        return (contribution_count)
    end

    func contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, github : felt
    }(token_id : Uint256, contribution_id : felt) -> (contribution : Contribution):
        let (contribution) = IGithub.contribution(github, token_id, contribution_id)
        return (contribution)
    end
end
