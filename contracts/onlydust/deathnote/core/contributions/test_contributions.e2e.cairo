%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.contributions import IContributions
from onlydust.deathnote.core.contributions.library import Contribution, Status
from onlydust.deathnote.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin'
const FEEDER = 'feeder'

#
# Tests
#
@view
func __setup__{syscall_ptr : felt*, range_check_ptr}():
    tempvar contributions_contract
    %{
        context.contributions_contract = deploy_contract("./contracts/onlydust/deathnote/core/contributions/contributions.cairo", [ids.ADMIN]).contract_address
        ids.contributions_contract = context.contributions_contract
        stop_prank = start_prank(ids.ADMIN, ids.contributions_contract)
    %}
    IContributions.grant_feeder_role(contributions_contract, FEEDER)
    %{ stop_prank() %}
    return ()
end

@view
func test_contributions_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    let (contributions) = contributions_access.deployed()

    let CONTRIBUTOR_ID = Uint256(12, 0)

    with contributions:
        contributions_access.add_contribution(
            CONTRIBUTOR_ID, Contribution('onlydust', 'starklings', 23, Status.OPEN)
        )
        contributions_access.add_contribution(
            CONTRIBUTOR_ID, Contribution('onlydust', 'starklings', 24, Status.OPEN)
        )
        let (contribution_count) = contributions_access.contribution_count(CONTRIBUTOR_ID)
        assert contribution_count = 2

        let (contribution) = contributions_access.contribution(CONTRIBUTOR_ID, 0)
    end

    with contribution:
        assert_contribution_that.repo_owner_is('onlydust')
        assert_contribution_that.repo_name_is('starklings')
        assert_contribution_that.pr_id_is(23)
        assert_contribution_that.pr_status_is(Status.OPEN)
    end

    with contributions:
        contributions_access.add_contribution(
            CONTRIBUTOR_ID, Contribution('onlydust', 'starklings', 23, Status.MERGED)
        )
        let (contribution_count) = contributions_access.contribution_count(CONTRIBUTOR_ID)
        assert contribution_count = 2

        let (contribution) = contributions_access.contribution(CONTRIBUTOR_ID, 0)
    end

    with contribution:
        assert_contribution_that.repo_owner_is('onlydust')
        assert_contribution_that.repo_name_is('starklings')
        assert_contribution_that.pr_id_is(23)
        assert_contribution_that.pr_status_is(Status.MERGED)
    end

    return ()
end

#
# Libraries
#
namespace contributions_access:
    func deployed() -> (contributions_contract : felt):
        tempvar contributions_contract
        %{ ids.contributions_contract = context.contributions_contract %}
        return (contributions_contract)
    end

    func add_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contributor_id : Uint256, contribution : Contribution):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.add_contribution(contributions, contributor_id, contribution)
        %{ stop_prank() %}
        return ()
    end

    func contribution_count{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contributor_id : Uint256) -> (contribution_count : felt):
        let (contribution_count) = IContributions.contribution_count(contributions, contributor_id)
        return (contribution_count)
    end

    func contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contributor_id : Uint256, contribution_id : felt) -> (contribution : Contribution):
        let (contribution) = IContributions.contribution(contributions, contributor_id, contribution_id)
        return (contribution)
    end
end
