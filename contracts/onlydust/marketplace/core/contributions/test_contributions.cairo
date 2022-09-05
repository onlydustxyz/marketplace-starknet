%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.marketplace.core.contributions.library import (
    contributions,
    Status,
    past_contributions_,
    ContributionId,
)
from onlydust.marketplace.core.contributions.access_control import access_control

from onlydust.marketplace.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin'
const REGISTRY = 'registry'
const PROJECT_ID = 'MyProject'
const LEAD_CONTRIBUTOR_ACCOUNT = 'lead'

@view
func test_lead_contributor_can_be_added_and_removed{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()
    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.add_lead_contributor_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT)
    contributions.remove_lead_contributor_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT)
    %{ stop_prank() %}

    %{
        expect_events(
            { "name": "LeadContributorAdded", "data": { "project_id": ids.PROJECT_ID,  "lead_contributor_account":  ids.LEAD_CONTRIBUTOR_ACCOUNT }},
            { "name": "LeadContributorRemoved", "data": { "project_id": ids.PROJECT_ID,  "lead_contributor_account": ids.LEAD_CONTRIBUTOR_ACCOUNT }},
        )
    %}

    return ()
end

@view
func lead_can_test_new_contribution_can_be_added{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    let (contribution2) = contributions.new_contribution(PROJECT_ID, 2, 0)
    %{ stop_prank() %}

    let (count, contribs) = contributions.all_contributions()

    assert 2 = count

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(contribution1.id)
        assert_contribution_that.project_id_is(contribution1.project_id)
        assert_contribution_that.status_is(Status.OPEN)
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(contribution2.id)
        assert_contribution_that.project_id_is(contribution2.project_id)
        assert_contribution_that.status_is(Status.OPEN)
    end

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionCreated", "data": {"contribution_id": 2, "project_id": ids.PROJECT_ID,  "issue_number": 2, "gate": 0}},
           )
    %}
    return ()
end

@view
func test_new_contribution_can_be_added_by_lead_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.add_lead_contributor_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    contributions.new_contribution(PROJECT_ID, 1, 0)
    %{ stop_prank() %}

    return ()
end

@view
func test_same_contribution_cannot_be_added_twice{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contributions: Contribution already exist")
    %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    let (contribution2) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{ stop_prank() %}

    return ()
end

@view
func test_feeder_can_delete_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.delete_contribution(contribution1.id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution1.id)
    with contribution:
        assert_contribution_that.status_is(Status.NONE)
    end

    %{
        expect_events(
               {"name": "ContributionDeleted", "data": {"contribution_id": 1}}
           )
    %}

    return ()
end

@view
func test_anyone_cannot_delete_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{ stop_prank() %}

    %{ expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required") %}
    contributions.delete_contribution(contribution1.id)

    return ()
end

@view
func test_only_open_delete_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    let contributor_test = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (local contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{ stop_prank() %}

    %{ expect_revert(error_message="Contributions: Contribution is not OPEN") %}

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    # set status to ASSIGNED
    contributions.assign_contributor_to_contribution(contribution1.id, contributor_test)
    contributions.delete_contribution(contribution1.id)
    %{ stop_prank() %}

    return ()
end

@view
func test_lead_can_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (contribution) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(contributor_id)
    end

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": 1, "high": 0}}},
           )
    %}
    return ()
end

@view
func test_anyone_cannot_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required")
    %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)

    return ()
end

@view
func test_cannot_assign_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) 
        expect_revert(error_message="Contributions: Contribution does not exist")
    %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_assign_twice_a_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ expect_revert(error_message="Contributions: Contribution is not OPEN") %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_assign_contribution_to_non_eligible_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 3)
    %{ expect_revert(error_message="Contributions: Contributor is not eligible") %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_can_assign_gated_contribution_eligible_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let gated_contribution_id = ContributionId(2)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    # Create a non-gated contribution
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)

    # Create a gated contribution
    let (_) = contributions.new_contribution(PROJECT_ID, 2, 1)

    # Assign and validate the non-gated contribution
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.validate_contribution(contribution_id)

    # Assign and validate the gated contribution
    contributions.assign_contributor_to_contribution(gated_contribution_id, contributor_id)
    contributions.validate_contribution(gated_contribution_id)
    %{ stop_prank() %}

    let (past_contributions) = contributions.past_contributions(contributor_id)
    assert 2 = past_contributions

    return ()
end

@view
func test_contribution_creation_with_invalid_project_id_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contributions: Invalid project ID")
    %}
    let (_) = contributions.new_contribution(0, 1, 0)
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_invalid_contribution_count_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contributions: Invalid gate")
    %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, -1)
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_add_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required") %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)

    return ()
end

@view
func test_lead_can_unassign_contribution_from_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.OPEN)
        assert_contribution_that.contributor_is(Uint256(0, 0))
    end

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID, "issue_number": 1, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": 1, "high": 0}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": 1}},
           )
    %}

    return ()
end

@view
func test_anyone_cannot_unassign_contribution_from_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required")
    %}
    contributions.unassign_contributor_from_contribution(contribution_id)

    return ()
end

@view
func test_cannot_unassign_from_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) 
        expect_revert(error_message="Contributions: Contribution does not exist")
    %}
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_unassign_contribution_if_not_assigned{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_lead_can_validate_assigned_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionAssigned", "data": {"contribution_id": 1, "contributor_id": {"low": 1, "high": 0}}},
               {"name": "ContributionValidated", "data": {"contribution_id": 1}},
           )
    %}

    return ()
end

@view
func test_anyone_cannot_validate_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role required")
    %}
    contributions.validate_contribution(contribution_id)

    return ()
end

@view
func test_cannot_validate_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)

    %{
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) 
        expect_revert(error_message="Contributions: Contribution does not exist")
    %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_cannot_validate_contribution_if_not_assigned{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_lead_can_modify_gate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)
    let validator_account = 'validator'

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.modify_gate(contribution_id, 3)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.gate_is(3)
    end

    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": 1, "project_id": ids.PROJECT_ID,  "issue_number": 1, "gate": 0}},
               {"name": "ContributionGateChanged", "data": {"contribution_id": 1, "gate": 3}},
           )
    %}

    return ()
end

@view
func test_anyone_cannot_modify_gate{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contribution_id = ContributionId(1)
    let contributor_id = Uint256(1, 0)
    let validator_account = 'validator'

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let (_) = contributions.new_contribution(PROJECT_ID, 1, 0)
    %{
        stop_prank ()
        expect_revert(error_message="Contributions: LEAD_CONTRIBUTOR role require")
    %}
    contributions.modify_gate(contribution_id, 3)

    return ()
end

@view
func test_anyone_can_get_past_contributions_count{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()
    let contributor_id = Uint256('greg', '@onlydust')
    fixture.validate_two_contributions(contributor_id)

    let (past_contribution_count) = contributions.past_contributions(contributor_id)
    assert 2 = past_contribution_count

    return ()
end

@view
func test_anyone_can_list_open_contributions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let contribution1_id = ContributionId(1)
    let (contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution1_id, Uint256(1, 0))

    let contribution2_id = ContributionId(2)
    let (local contribution2) = contributions.new_contribution(PROJECT_ID, 2, 0)
    %{ stop_prank() %}

    let (contribs_len, contribs) = contributions.all_open_contributions()
    assert 1 = contribs_len
    assert contribution2 = contribs[0]

    return ()
end

@view
func test_anyone_can_list_assigned_contributions{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let contribution1_id = ContributionId(1)
    let (contribution1) = contributions.new_contribution(PROJECT_ID, 1, 0)
    contributions.assign_contributor_to_contribution(contribution1_id, contributor_id)

    let contribution2_id = ContributionId(2)
    let (local contribution2) = contributions.new_contribution(PROJECT_ID, 2, 0)
    %{ stop_prank() %}

    let (contribs_len, contribs) = contributions.assigned_contributions(contributor_id)
    assert 1 = contribs_len
    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(contribution1_id)
        assert_contribution_that.project_id_is(PROJECT_ID)
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(contributor_id)
    end

    return ()
end

@view
func test_anyone_can_list_contributions_eligible_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    let contributor_id = Uint256('greg', '@onlydust')

    fixture.validate_two_contributions(contributor_id)

    # Create different contributions
    %{ stop_prank = start_prank(ids.ADMIN) %}
    access_control.grant_lead_contributor_role_for_project('OnlyDust', LEAD_CONTRIBUTOR_ACCOUNT)
    %{ stop_prank() %}
    %{ stop_prank = start_prank(ids.ADMIN) %}
    access_control.grant_lead_contributor_role_for_project('Briq', LEAD_CONTRIBUTOR_ACCOUNT)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
    let contribution_id = ContributionId(3)  # 'open non-gated'
    let (contribution1) = contributions.new_contribution('OnlyDust', 1, 0)

    let contribution_id = ContributionId(4)  # 'assigned non-gated'
    let (local contribution2) = contributions.new_contribution('Briq', 1, 0)
    contributions.assign_contributor_to_contribution(contribution_id, Uint256(1, 0))

    let contribution_id = ContributionId(5)  # 'open gated'
    let (local contribution3) = contributions.new_contribution('Briq', 2, 1)

    let contribution_id = ContributionId(6)  # 'open gated too_high'
    let (local contribution5) = contributions.new_contribution('Briq', 3, 3)

    %{ stop_prank() %}

    let (contribs_len, contribs) = contributions.eligible_contributions(contributor_id)
    assert 5 = contribs_len

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(ContributionId(1))
        assert_contribution_that.project_id_is('Random')
        assert_contribution_that.contributor_is(contributor_id)
    end

    let contribution = contribs[2]
    with contribution:
        assert_contribution_that.id_is(ContributionId(3))
        assert_contribution_that.project_id_is('OnlyDust')
        assert_contribution_that.contributor_is(Uint256(0, 0))
    end

    return ()
end

@view
func test_lead_can_add_member_to_project{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    let contributor_account = 'contributor'
    tempvar registry_contract = REGISTRY

    %{
        stop_mock = mock_call(ids.registry_contract, "get_user_information", [12345, 42, 0, 0])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    contributions.add_member_for_project(PROJECT_ID, contributor_account)
    %{
        stop_prank()
        stop_mock()
    %}

    %{
        expect_events(
            { "name": "ProjectMemberAdded", "data": { "project_id": ids.PROJECT_ID,  "contributor_account":  ids.contributor_account, "contributor_id": {"low": 42, "high": 0} }},
        )
    %}
    return ()
end

namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        contributions.initialize(ADMIN)
        contributions.set_registry_contract_address(REGISTRY)
        %{ stop_prank = start_prank(ids.ADMIN) %}
        access_control.grant_lead_contributor_role_for_project(PROJECT_ID, LEAD_CONTRIBUTOR_ACCOUNT)
        %{ stop_prank() %}
        return ()
    end

    func validate_two_contributions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contributor_id : Uint256):
        let contribution_id = ContributionId(1)
        let gated_contribution_id = ContributionId(2)

        %{ stop_prank = start_prank(ids.ADMIN) %}
        access_control.grant_lead_contributor_role_for_project('Random', LEAD_CONTRIBUTOR_ACCOUNT)
        %{ stop_prank() %}

        %{ stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT) %}
        # Create a non-gated contribution
        let (contribution) = contributions.new_contribution('Random', 1, 0)

        # Create a gated contribution
        let (contribution) = contributions.new_contribution('Random', 2, 1)

        # Assign and validate the non-gated contribution
        contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
        contributions.validate_contribution(contribution_id)

        # Assign and validate the gated contribution
        contributions.assign_contributor_to_contribution(gated_contribution_id, contributor_id)
        contributions.validate_contribution(gated_contribution_id)
        %{ stop_prank() %}

        let (past_contributions) = contributions.past_contributions(contributor_id)
        assert 2 = past_contributions

        return ()
    end
end
