%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.registry import IRegistry, UserInformation
from onlydust.deathnote.interfaces.contributions import IContributions
from onlydust.deathnote.interfaces.profile import IProfile
from onlydust.deathnote.core.contributions.library import Contribution, Status
from onlydust.deathnote.test.libraries.user import assert_user_that
from onlydust.deathnote.test.libraries.contributions import assert_contribution_that

const ADMIN = 'onlydust'
const FEEDER = 'feeder'
const REGISTERER = 'register'
const CONTRIBUTOR = '0xdead'
const GITHUB_ID = 'user123'

#
# Tests
#
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tempvar registry
    tempvar profile_contract
    tempvar contributions_contract
    %{
        ids.registry = deploy_contract("./contracts/onlydust/deathnote/core/registry/registry.cairo", [ids.ADMIN]).contract_address 
        ids.profile_contract = deploy_contract("./contracts/onlydust/deathnote/core/profile/profile.cairo", [ids.ADMIN]).contract_address 
        ids.contributions_contract = deploy_contract("./contracts/onlydust/deathnote/core/contributions/contributions.cairo", [ids.ADMIN]).contract_address 

        context.registry = ids.registry
        context.contributions_contract = ids.contributions_contract
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.registry, ids.profile_contract, ids.contributions_contract] ] %}
    IRegistry.set_profile_contract(registry, profile_contract)
    IRegistry.grant_registerer_role(registry, REGISTERER)
    IProfile.grant_minter_role(profile_contract, registry)
    IContributions.grant_feeder_role(contributions_contract, FEEDER)
    %{ [stop_prank() for stop_prank in stop_pranks] %}

    return ()
end

@view
func test_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    let (registry) = registry_access.deployed()

    with registry:
        let (local user) = registry_access.register_github_identifier(CONTRIBUTOR, GITHUB_ID)
    end

    with user:
        assert_user_that.github_identifier_is(GITHUB_ID)
    end

    let (contributions) = contributions_access.deployed()
    with contributions:
        contributions_access.new_contribution(123, 'MyProject', 0, 'validator')
        contributions_access.new_contribution(124, 'MyProject', 0, 'validator')

        let contributor_id = user.contributor_id
        contributions_access.assign_contributor_to_contribution(123, contributor_id)

        contributions_access.assign_contributor_to_contribution(124, contributor_id)
        contributions_access.unassign_contributor_from_contribution(124)

        let (count, contribs) = contributions_access.all_contributions()
    end

    assert 2 = count

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(123)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(contributor_id)
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(124)
        assert_contribution_that.project_id_is('MyProject')
        assert_contribution_that.status_is(Status.OPEN)
    end

    return ()
end

#
# Libraries
#
namespace registry_access:
    func deployed() -> (registry : felt):
        tempvar registry
        %{ ids.registry = context.registry %}
        return (registry)
    end

    func register_github_identifier{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, registry : felt
    }(contributor : felt, identifier : felt) -> (user : UserInformation):
        %{ stop_prank = start_prank(ids.REGISTERER, ids.registry) %}
        IRegistry.register_github_identifier(registry, contributor, identifier)
        %{ stop_prank() %}

        let (user) = IRegistry.get_user_information(registry, contributor)
        return (user)
    end
end

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

    func all_contributions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }() -> (contribs_len, contribs : Contribution*):
        let (contribs_len, contribs) = IContributions.all_contributions(contributions)
        return (contribs_len, contribs)
    end

    func contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : felt) -> (contribution : Contribution):
        let (contribution) = IContributions.contribution(contributions, contribution_id)
        return (contribution)
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
end
