%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.library import (
    contributions,
    Contribution,
    Status,
    Role,
    past_contributions_,
)
from onlydust.deathnote.test.libraries.contributions import assert_contribution_that

const ADMIN = 'admin'
const FEEDER = 'feeder'
const REGISTRY = 'registry'

@view
func test_new_contribution_can_be_added{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (local contribution1) = contributions.new_contribution(123, 'MyProject', 0, 'validator')
    let (contribution1) = contributions.new_contribution(123, 'MyProject', 0, 'validator')  # adding twice the same to test update
    let (contribution2) = contributions.new_contribution(124, 'MyProject', 0, 'validator')
    %{ stop_prank() %}

    let (count, contribs) = contributions.all_contributions()

    assert 2 = count

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(contribution1.id)
        assert_contribution_that.project_id_is(contribution1.project_id)
        assert_contribution_that.status_is(Status.OPEN)
        assert_contribution_that.validator_is('validator')
    end

    let contribution = contribs[1]
    with contribution:
        assert_contribution_that.id_is(contribution2.id)
        assert_contribution_that.project_id_is(contribution2.project_id)
        assert_contribution_that.status_is(Status.OPEN)
        assert_contribution_that.validator_is('validator')
    end

    return ()
end

@view
func test_new_contribution_with_0x0_validator_can_be_added{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals

    fixture.initialize()

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (local contribution) = contributions.new_contribution(123, 'MyProject', 0, 0x0)
    %{ stop_prank() %}

    let (count, contribs) = contributions.all_contributions()

    assert 1 = count

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(contribution.id)
        assert_contribution_that.project_id_is(contribution.project_id)
        assert_contribution_that.status_is(Status.OPEN)
        assert_contribution_that.validator_is(0x0)
    end

    return ()
end

@view
func test_feeder_can_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (contribution) = contributions.new_contribution(
        contribution_id, 'MyProject', 0, 'validator'
    )
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.ASSIGNED)
        assert_contribution_that.contributor_is(contributor_id)
    end

    return ()
end

@view
func test_anyone_cannot_assign_contribution_to_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(123, 'MyProject', 0, 'validator')
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: FEEDER role required")
    %}
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)

    return ()
end

@view
func test_cannot_assign_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{
        stop_prank = start_prank(ids.FEEDER) 
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

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
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

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 3, 'validator')
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

    const contribution_id = 123
    const gated_contribution_id = 124
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    # Create a non-gated contribution
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')

    # Create a gated contribution
    let (_) = contributions.new_contribution(gated_contribution_id, 'MyProject', 1, 'validator')

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
func test_contribution_creation_with_invalid_id_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid contribution ID")
    %}
    let (_) = contributions.new_contribution(0, 'MyProject', 0, 'validator')
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_invalid_project_id_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid project ID")
    %}
    let (_) = contributions.new_contribution(123, 0, 0, 'validator')
    %{ stop_prank() %}

    return ()
end

@view
func test_contribution_creation_with_invalid_contribution_count_is_reverted{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.FEEDER)
        expect_revert(error_message="Contributions: Invalid contribution count required")
    %}
    let (_) = contributions.new_contribution(123, 'MyProject', -1, 'validator')
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_add_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="Contributions: FEEDER role required") %}
    let (_) = contributions.new_contribution(123, 'MyProject', 0, 'validator')

    return ()
end

@view
func test_feeder_can_unassign_contribution_from_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.OPEN)
        assert_contribution_that.contributor_is(Uint256(0, 0))
    end

    return ()
end

@view
func test_anyone_cannot_unassign_contribution_from_contributor{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: FEEDER role required")
    %}
    contributions.unassign_contributor_from_contribution(contribution_id)

    return ()
end

@view
func test_cannot_unassign_from_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{
        stop_prank = start_prank(ids.FEEDER) 
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

    const contribution_id = 123

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.unassign_contributor_from_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_feeder_can_validate_assigned_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    return ()
end

@view
func test_feeder_can_validate_assigned_contribution_when_validator_is_0x0{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 0x0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    return ()
end

@view
func test_validator_can_validate_assigned_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)
    let validator_account = 'validator'

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, validator_account)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.validator_account) %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    let (contribution) = contributions.contribution(contribution_id)
    with contribution:
        assert_contribution_that.status_is(Status.COMPLETED)
    end

    return ()
end

@view
func test_validator_cannot_validate_assigned_contribution_when_validator_account_is_0x0{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)
    let validator_account = 'validator'

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 0x0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        stop_prank = start_prank(ids.validator_account)
        expect_revert(error_message="Contributions: caller cannot validate this contribution")
    %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_anyone_cannot_validate_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: caller cannot validate this contribution")
    %}
    contributions.validate_contribution(contribution_id)

    return ()
end

@view
func test_anyone_cannot_validate_contribution_with_0x0_validator{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123
    let contributor_id = Uint256(1, 0)

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 0x0)
    contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
    %{
        stop_prank() 
        expect_revert(error_message="Contributions: caller cannot validate this contribution")
    %}
    contributions.validate_contribution(contribution_id)

    return ()
end

@view
func test_cannot_validate_non_existent_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const contribution_id = 123

    %{
        stop_prank = start_prank(ids.FEEDER) 
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

    const contribution_id = 123

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let (_) = contributions.new_contribution(contribution_id, 'MyProject', 0, 'validator')
    %{ expect_revert(error_message="Contributions: Contribution is not ASSIGNED") %}
    contributions.validate_contribution(contribution_id)
    %{ stop_prank() %}

    return ()
end

@view
func test_admin_cannot_revoke_himself{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{
        stop_prank = start_prank(ids.ADMIN)
        expect_revert(error_message="Contributions: Cannot self renounce to ADMIN role")
    %}
    contributions.revoke_admin_role(ADMIN)

    %{ stop_prank() %}

    return ()
end

@view
func test_admin_can_transfer_ownership{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    const NEW_ADMIN = 'new_admin'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.grant_admin_role(NEW_ADMIN)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.NEW_ADMIN) %}
    contributions.revoke_admin_role(ADMIN)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.ADMIN, ids.NEW_ADMIN, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.ADMIN, ids.ADMIN, ids.NEW_ADMIN]}
        )
    %}

    return ()
end

@view
func test_anyone_cannot_grant_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    contributions.grant_admin_role(FEEDER)

    return ()
end

@view
func test_anyone_cannot_revoke_role{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    fixture.initialize()

    %{ expect_revert(error_message="AccessControl: caller is missing role 0") %}
    contributions.revoke_admin_role(ADMIN)

    return ()
end

@view
func test_admin_can_grant_and_revoke_roles{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}():
    alloc_locals
    fixture.initialize()

    const RANDOM_ADDRESS = 'rand'

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.grant_feeder_role(RANDOM_ADDRESS)
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.RANDOM_ADDRESS) %}
    let (local contribution) = contributions.new_contribution(123, 'MyProject', 0, 'validator')
    %{ stop_prank() %}

    %{ stop_prank = start_prank(ids.ADMIN) %}
    contributions.revoke_feeder_role(RANDOM_ADDRESS)
    %{
        stop_prank() 
        expect_events(
            {"name": "RoleGranted", "data": [ids.Role.FEEDER, ids.RANDOM_ADDRESS, ids.ADMIN]},
            {"name": "RoleRevoked", "data": [ids.Role.FEEDER, ids.RANDOM_ADDRESS, ids.ADMIN]}
        )
    %}

    %{
        stop_prank = start_prank(ids.RANDOM_ADDRESS) 
        expect_revert(error_message='Contributions: FEEDER role required')
    %}
    contributions.new_contribution(123, 'MyProject', 0, 'validator')
    %{ stop_prank() %}

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

    %{ stop_prank = start_prank(ids.FEEDER) %}
    const contribution1_id = 123
    let (contribution1) = contributions.new_contribution(
        contribution1_id, 'MyProject', 0, 'validator'
    )
    contributions.assign_contributor_to_contribution(contribution1_id, Uint256(1, 0))

    const contribution2_id = 124
    let (local contribution2) = contributions.new_contribution(
        contribution2_id, 'MyProject', 0, 'validator'
    )
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

    %{ stop_prank = start_prank(ids.FEEDER) %}
    const contribution1_id = 123
    let (contribution1) = contributions.new_contribution(
        contribution1_id, 'MyProject', 0, 'validator'
    )
    contributions.assign_contributor_to_contribution(contribution1_id, contributor_id)

    const contribution2_id = 124
    let (local contribution2) = contributions.new_contribution(
        contribution2_id, 'MyProject', 0, 'validator'
    )
    %{ stop_prank() %}

    let (contribs_len, contribs) = contributions.assigned_contributions(contributor_id)
    assert 1 = contribs_len
    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is(contribution1_id)
        assert_contribution_that.project_id_is('MyProject')
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

    %{ stop_prank = start_prank(ids.FEEDER) %}
    let contribution_id = 1  # 'open non-gated'
    let (contribution1) = contributions.new_contribution(
        contribution_id, 'OnlyDust', 0, 'validator'
    )

    let contribution_id = 2  # 'assigned non-gated'
    let (local contribution2) = contributions.new_contribution(
        contribution_id, 'Briq', 0, 'validator'
    )
    contributions.assign_contributor_to_contribution(contribution_id, Uint256(1, 0))

    let contribution_id = 3  # 'open gated'
    let (local contribution3) = contributions.new_contribution(
        contribution_id, 'Briq', 1, 'validator'
    )

    let contribution_id = 4  # 'open gated too_high'
    let (local contribution5) = contributions.new_contribution(
        contribution_id, 'Briq', 3, 'validator'
    )

    %{ stop_prank() %}

    let (contribs_len, contribs) = contributions.eligible_contributions(contributor_id)
    assert 5 = contribs_len

    let contribution = contribs[0]
    with contribution:
        assert_contribution_that.id_is('exercise')
        assert_contribution_that.project_id_is('OnlyDust')
        assert_contribution_that.contributor_is(contributor_id)
    end

    let contribution = contribs[2]
    with contribution:
        assert_contribution_that.id_is(1)
        assert_contribution_that.project_id_is('OnlyDust')
        assert_contribution_that.contributor_is(Uint256(0, 0))
    end

    return ()
end

namespace fixture:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        contributions.initialize(ADMIN)
        %{ stop_prank = start_prank(ids.ADMIN) %}
        contributions.grant_feeder_role(FEEDER)
        %{ stop_prank() %}
        return ()
    end

    func validate_two_contributions{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contributor_id : Uint256):
        const contribution_id = 'exercise'
        const gated_contribution_id = 'briqgame'

        %{ stop_prank = start_prank(ids.FEEDER) %}
        # Create a non-gated contribution
        let (contribution) = contributions.new_contribution(
            contribution_id, 'OnlyDust', 0, 'validator'
        )

        # Create a gated contribution
        let (contribution) = contributions.new_contribution(
            gated_contribution_id, 'Briq', 1, 'validator'
        )

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
