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
        contributions_access.new_contribution(Contribution(123, 456, Status.OPEN))
        contributions_access.new_contribution(Contribution(124, 456, Status.OPEN))

        contributions_access.assign_contributor_to_contribution(123, CONTRIBUTOR_ID)
        let (contribs_len, contribs) = contributions_access.all_contributions()
    end

    assert 2 = contribs_len

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(124)
        assert_contribution_that.project_id_is(456)
        assert_contribution_that.status_is(Status.OPEN)
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(123)
        assert_contribution_that.project_id_is(456)
        assert_contribution_that.status_is(Status.ASSIGNED)
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

    func new_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution : Contribution):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.new_contribution(contributions, contribution)
        %{ stop_prank() %}
        return ()
    end

    func assign_contributor_to_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : felt, contributor_id : Uint256):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.assign_contributor_to_contribution(
            contributions, contribution_id, contributor_id
        )
        %{ stop_prank() %}
        return ()
    end

    func contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : felt) -> (contribution : Contribution):
        let (contribution) = IContributions.contribution(contributions, contribution_id)
        return (contribution)
    end

    func all_contributions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }() -> (contribs_len, contribs : Contribution*):
        let (contribs_len, contribs) = IContributions.all_contributions(contributions)
        return (contribs_len, contribs)
    end
end
