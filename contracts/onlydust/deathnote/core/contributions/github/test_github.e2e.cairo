%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.contributions.github import IGithub
from onlydust.deathnote.core.contributions.github.library import Contribution, Status
from onlydust.deathnote.test.libraries.contributions.github import assert_github_contribution_that

const ADMIN = 'admin'

#
# Tests
#
@view
func __setup__():
    %{ context.github_contract = deploy_contract("./contracts/onlydust/deathnote/core/contributions/github/github.cairo", [ids.ADMIN]).contract_address %}
    return ()
end

@view
func test_github_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (github) = github_access.deployed()

    let TOKEN_ID = Uint256(12, 0)

    with github:
        github_access.add_contribution(
            TOKEN_ID, Contribution('onlydust', 'starklings', 23, Status.OPEN)
        )
        github_access.add_contribution(
            TOKEN_ID, Contribution('onlydust', 'starklings', 24, Status.OPEN)
        )
        let (contribution_count) = github_access.contribution_count(TOKEN_ID)
        assert contribution_count = 2

        let (contribution) = github_access.contribution(TOKEN_ID, 0)
    end

    with contribution:
        assert_github_contribution_that.repo_owner_is('onlydust')
        assert_github_contribution_that.repo_name_is('starklings')
        assert_github_contribution_that.pr_id_is(23)
        assert_github_contribution_that.pr_status_is(Status.OPEN)
    end

    with github:
        github_access.add_contribution(
            TOKEN_ID, Contribution('onlydust', 'starklings', 23, Status.MERGED)
        )
        let (contribution_count) = github_access.contribution_count(TOKEN_ID)
        assert contribution_count = 2

        let (contribution) = github_access.contribution(TOKEN_ID, 0)
    end

    with contribution:
        assert_github_contribution_that.repo_owner_is('onlydust')
        assert_github_contribution_that.repo_name_is('starklings')
        assert_github_contribution_that.pr_id_is(23)
        assert_github_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

#
# Libraries
#
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
