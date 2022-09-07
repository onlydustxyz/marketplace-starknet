%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.interfaces.registry import IRegistry, UserInformation
from onlydust.marketplace.interfaces.contributions import IContributions
from onlydust.marketplace.interfaces.profile import IProfile
from onlydust.marketplace.core.contributions.library import Contribution, Status, ContributionId
from onlydust.marketplace.test.libraries.user import assert_user_that
from onlydust.marketplace.test.libraries.contributions import assert_contribution_that

const ADMIN = 'onlydust'
const REGISTERER = 'register'
const CONTRIBUTOR = '0xcontributor'
const GITHUB_ID = 'user123'
const PROJECT_ID = 'MyProject'
const ID1 = 1000000 * PROJECT_ID + 1
const ID2 = 1000000 * PROJECT_ID + 2
const LEAD_CONTRIBUTOR_ACCOUNT = 'LeadContributor'

#
# Tests
#
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    tempvar registry
    tempvar profile_contract
    tempvar contributions_contract
    %{
        ids.registry = deploy_contract("./contracts/onlydust/marketplace/core/registry/registry.cairo", [ids.ADMIN]).contract_address 
        ids.profile_contract = deploy_contract("./contracts/onlydust/marketplace/core/profile/profile.cairo", [ids.ADMIN]).contract_address 
        ids.contributions_contract = deploy_contract("./contracts/onlydust/marketplace/core/contributions/contributions.cairo", [ids.ADMIN]).contract_address 

        context.registry = ids.registry
        context.contributions_contract = ids.contributions_contract
    %}

    %{ stop_pranks = [start_prank(ids.ADMIN, contract) for contract in [ids.registry, ids.profile_contract, ids.contributions_contract] ] %}
    IRegistry.set_profile_contract(registry, profile_contract)
    IRegistry.grant_registerer_role(registry, REGISTERER)
    IProfile.grant_minter_role(profile_contract, registry)
    IContributions.add_lead_contributor_for_project(
        contributions_contract, PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT
    )
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
        contributions_access.new_contribution(PROJECT_ID, 1, 0)
        contributions_access.new_contribution(PROJECT_ID, 2, 0)

        let contributor_id = user.contributor_id
        contributions_access.assign_contributor_to_contribution(ContributionId(1), contributor_id)

        contributions_access.assign_contributor_to_contribution(ContributionId(2), contributor_id)
        contributions_access.unassign_contributor_from_contribution(ContributionId(2))

        let (count, contribs) = contributions_access.all_contributions()
    end

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionCreated", "data": {"contribution_id": 2, "project_id": ids.PROJECT_ID,  "issue_number": 2, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": ids.user.contributor_id.low, "high": ids.user.contributor_id.high}}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 2, "contributor_id": {"low": ids.user.contributor_id.low, "high": ids.user.contributor_id.high}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": 2}},
           )
    %}

    assert 2 = count

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(ContributionId(1))
        assert_contribution_that.project_id_is(PROJECT_ID)
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(contributor_id)
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(ContributionId(2))
        assert_contribution_that.project_id_is(PROJECT_ID)
        assert_contribution_that.status_is(Status.OPEN)
    end

    with contributions:
        contributions_access.add_member_for_project(PROJECT_ID, CONTRIBUTOR)
    end

    %{
        expect_events(
            { "name": "ProjectMemberAdded", "data": { "project_id": ids.PROJECT_ID,  "contributor_account":  ids.CONTRIBUTOR }},
        )
    %}

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
    }(project_id : felt, issue_number : felt, gate : felt):
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.new_contribution(contributions, project_id, issue_number, gate)
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
    }(contribution_id : ContributionId) -> (contribution : Contribution):
        let (contribution) = IContributions.contribution(contributions, contribution_id)
        return (contribution)
    end

    func assign_contributor_to_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : ContributionId, contributor_id : Uint256):
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.assign_contributor_to_contribution(
            contributions, contribution_id, contributor_id
        )
        %{ stop_prank() %}
        return ()
    end

    func unassign_contributor_from_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(contribution_id : ContributionId):
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.unassign_contributor_from_contribution(contributions, contribution_id)
        %{ stop_prank() %}
        return ()
    end

    func add_member_for_project{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, contributions : felt
    }(project_id : felt, contributor_account : felt):
        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT, ids.contributions) %}
        IContributions.add_member_for_project(contributions, project_id, contributor_account)
        %{ stop_prank() %}
        return ()
    end
end
