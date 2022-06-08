%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.github.library import github, Contribution, Status
from onlydust.deathnote.test.libraries.contributions.github import assert_github_contribution_that

const OWNER = 'owner'

@view
func test_github_contribution_can_be_created{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let TOKEN_ID = Uint256(12, 0)
    let contribution = Contribution('onlydust', 'starkonquest', 23, Status.MERGED)

    %{ stop_prank = start_prank(ids.OWNER) %}
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

    %{ stop_prank = start_prank(ids.OWNER) %}
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

    %{ stop_prank = start_prank(ids.OWNER) %}
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

    %{ expect_revert(error_message="Ownable: caller is not the owner") %}
    github.add_contribution(
        Uint256(13, 0), Contribution('onlydust', 'starkonquest', 23, Status.REVIEW)
    )

    return ()
end

namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        github.initialize(OWNER)
        return ()
    end
end
