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

    let UNASSIGNED_CONTRIBUTION_ID = 1
    let FEEDER_VALIDATED_CONTRIBUTION_ID = 2
    let VALIDATOR_VALIDATED_CONTRIBUTION_ID = 3

    # Create two contributions and assign them a contibutor
    with contributions:
        contributions_access.new_contribution(
            UNASSIGNED_CONTRIBUTION_ID, 'MyProject', 0, 'validator'
        )
        contributions_access.new_contribution(
            FEEDER_VALIDATED_CONTRIBUTION_ID, 'MyProject', 0, 'validator'
        )
        contributions_access.new_contribution(
            VALIDATOR_VALIDATED_CONTRIBUTION_ID, 'MyProject', 0, 'validator'
        )

        contributions_access.assign_contributor_to_contribution(
            UNASSIGNED_CONTRIBUTION_ID, CONTRIBUTOR_ID
        )
        contributions_access.unassign_contributor_from_contribution(UNASSIGNED_CONTRIBUTION_ID)

        contributions_access.assign_contributor_to_contribution(
            FEEDER_VALIDATED_CONTRIBUTION_ID, CONTRIBUTOR_ID
        )
        contributions_access.assign_contributor_to_contribution(
            VALIDATOR_VALIDATED_CONTRIBUTION_ID, CONTRIBUTOR_ID
        )

        let (contribs_len, contribs) = contributions_access.all_contributions()
    end

    assert 3 = contribs_len

    # Check unassigned contribution state
    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(UNASSIGNED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.OPEN)
    end

    # Check assigned contributions state
    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(FEEDER_VALIDATED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(CONTRIBUTOR_ID)
    end
    let contribution = contribs[2]
    with contribution:
        assert_contribution_that.id_is(VALIDATOR_VALIDATED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(CONTRIBUTOR_ID)
    end

    # Check the open contribution listing only returns the unassigned ones
    with contributions:
        let (contribs_len, contribs) = contributions_access.all_open_contributions()
    end
    assert 1 = contribs_len

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(UNASSIGNED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.OPEN)
    end

    # Check assigned contribution state
    with contributions:
        let (contribs_len, contribs) = contributions_access.assigned_contributions(CONTRIBUTOR_ID)
    end

    assert 2 = contribs_len

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(FEEDER_VALIDATED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(CONTRIBUTOR_ID)
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(VALIDATOR_VALIDATED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(CONTRIBUTOR_ID)
    end

    # Check modify contribution count on unassigned works
    with contributions:
        contributions_access.modify_contribution_count(UNASSIGNED_CONTRIBUTION_ID, 10)
        let (contribution) = contributions_access.contribution(UNASSIGNED_CONTRIBUTION_ID)
    end

    with contribution:
        assert_contribution_that.id_is(UNASSIGNED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.gate_is(10)
        assert_contribution_that.status_is(Status.OPEN)
    end


    # Check validate contribution by feeder works
    with contributions:
        contributions_access.validate_contribution_as(FEEDER_VALIDATED_CONTRIBUTION_ID, FEEDER)
        let (contribution) = contributions_access.contribution(FEEDER_VALIDATED_CONTRIBUTION_ID)
    end

    with contribution:
        assert_contribution_that.id_is(FEEDER_VALIDATED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    # Check validate contribution by validator works
    with contributions:
        contributions_access.validate_contribution_as(
            VALIDATOR_VALIDATED_CONTRIBUTION_ID, 'validator'
        )
        let (contribution) = contributions_access.contribution(VALIDATOR_VALIDATED_CONTRIBUTION_ID)
    end

    with contribution:
        assert_contribution_that.id_is(VALIDATOR_VALIDATED_CONTRIBUTION_ID)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    # Check remove contribution works 
    with contributions:
        contributions_access.remove_contribution(UNASSIGNED_CONTRIBUTION_ID)
        let (contribs_len, contribs) = contributions_access.all_contributions()
    end

    assert 2 = contribs_len
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
    }(
        contribution_id : felt,
        project_id : felt,
        contribution_count_required : felt,
        validator_account : felt,
    ):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.new_contribution(
            contributions,
            contribution_id,
            project_id,
            contribution_count_required,
            validator_account,
        )
        %{ stop_prank() %}
        return ()
    end
    
    func remove_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(
        contribution_id : felt
    ):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.remove_contribution(
            contributions, contribution_id
        )
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

    func unassign_contributor_from_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : felt):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.unassign_contributor_from_contribution(contributions, contribution_id)
        %{ stop_prank() %}
        return ()
    end

    func validate_contribution_as{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : felt, caller : felt):
        %{ stop_prank = start_prank(ids.caller, ids.contributions) %}
        IContributions.validate_contribution(contributions, contribution_id)
        %{ stop_prank() %}
        return ()
    end

    func modify_contribution_count{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : felt, count : felt):
        %{ stop_prank = start_prank(ids.FEEDER, ids.contributions) %}
        IContributions.modify_contribution_count_required(contributions, contribution_id, count)
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

    func all_open_contributions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }() -> (contribs_len, contribs : Contribution*):
        let (contribs_len, contribs) = IContributions.all_open_contributions(contributions)
        return (contribs_len, contribs)
    end

    func assigned_contributions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contributor_id : Uint256) -> (contribs_len, contribs : Contribution*):
        let (contribs_len, contribs) = IContributions.assigned_contributions(
            contributions, contributor_id
        )
        return (contribs_len, contribs)
    end
end
