%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt, assert_le, assert_not_zero, sign
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address

from onlydust.stream.default_implementation import stream
from onlydust.marketplace.core.contributions.access_control import (
    access_control,
    LeadContributorAdded,
    LeadContributorRemoved,
    ProjectMemberAdded,
    ProjectMemberRemoved,
)

#
# Enums
#
struct DeprecatedStatus:
    member OPEN : felt
    member ASSIGNED : felt
    member COMPLETED : felt
    member ABANDONED : felt
end

struct Status:
    member NONE : felt
    member OPEN : felt
    member ASSIGNED : felt
    member COMPLETED : felt
    member ABANDONED : felt
end

#
# Structs
#
struct DeprecatedContribution:
    member id : felt
    member project_id : felt
    member status : felt
    member contributor_id : Uint256
    member gate : felt
    member validator_account : felt
end

struct ContributionId:
    member inner : felt
end

struct Contribution:
    member id : ContributionId
    member project_id : felt
    member status : felt
    member gate : felt
    member contributor_id : Uint256
end

#
# Events
#
@event
func ContributionCreated(
    contribution_id : felt, project_id : felt, issue_number : felt, gate : felt
):
end

@event
func ContributionDeleted(contribution_id : felt):
end

@event
func ContributionAssigned(contribution_id : felt, contributor_id : Uint256):
end

@event
func ContributionUnassigned(contribution_id : felt):
end

@event
func ContributionClaimed(contribution_id : felt, contributor_id : Uint256):
end

@event
func ContributionValidated(contribution_id : felt):
end

@event
func ContributionGateChanged(contribution_id : felt, gate : felt):
end

#
# Storage
#
@storage_var
func contribution_project_id(contribution_id : ContributionId) -> (project_id : felt):
end

@storage_var
func contribution_status_(contribution_id : ContributionId) -> (status : felt):
end

@storage_var
func contribution_contributor_(contribution_id : ContributionId) -> (contributor_id : Uint256):
end

@storage_var
func contribution_gate_(contribution_id : ContributionId) -> (gate : felt):
end

@storage_var
func contribution_count_() -> (contribution_count : felt):
end

@storage_var
func past_contributions_(contributor_id : Uint256) -> (contribution_count : felt):
end

@storage_var
func github_ids_to_contribution_id(project_id : felt, issue_numer : felt) -> (
    contribution_id : ContributionId
):
end

#
# Functions
#
namespace contributions:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        admin : felt
    ):
        access_control.initialize(admin)
        return ()
    end

    #
    # Write
    #

    # Add a contribution for a given token id
    func new_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, issue_number : felt, gate : felt
    ) -> (contribution : Contribution):
        alloc_locals

        project_access.assert_project_id_is_valid(project_id)
        access_control.only_lead_contributor(project_id)

        with_attr error_message("Contributions: Invalid gate"):
            let (gate_sign) = sign(gate)
            assert 0 = gate_sign * (1 - gate_sign)
            assert_nn(gate)
        end

        github_access.only_new(project_id, issue_number)

        let (contribution_count) = contribution_count_.read()
        let new_count = contribution_count + 1
        let id = ContributionId(new_count)

        # Update storage
        contribution_status_.write(id, Status.OPEN)
        contribution_gate_.write(id, gate)
        contribution_project_id.write(id, project_id)
        contribution_count_.write(new_count)
        github_ids_to_contribution_id.write(project_id, issue_number, id)

        ContributionCreated.emit(new_count, project_id, issue_number, gate)

        let contribution = Contribution(id, project_id, Status.OPEN, gate, Uint256(0, 0))

        return (contribution)
    end

    # Delete a contribution for a given contribution_id
    func delete_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId
    ):
        let (project_id) = project_access.find_contribution_project(contribution_id)
        access_control.only_lead_contributor(project_id)
        status_access.only_open(contribution_id)

        # Update storage
        contribution_status_.write(contribution_id, Status.NONE)
        contribution_gate_.write(contribution_id, 0)
        contribution_project_id.write(contribution_id, 0)

        ContributionDeleted.emit(contribution_id.inner)

        return ()
    end

    # Assign a contributor to a contribution
    func assign_contributor_to_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId, contributor_id : Uint256):
        let (project_id) = project_access.find_contribution_project(contribution_id)
        access_control.only_lead_contributor(project_id)

        internal.assign_contributor_to_contribution(contribution_id, contributor_id)

        # Emit event
        ContributionAssigned.emit(contribution_id.inner, contributor_id)

        return ()
    end

    # Unassign a contributor from a contribution
    func unassign_contributor_from_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId):
        let (project_id) = project_access.find_contribution_project(contribution_id)
        access_control.only_lead_contributor(project_id)

        status_access.only_assigned(contribution_id)

        # Update storage
        contribution_contributor_.write(contribution_id, Uint256(0, 0))
        contribution_status_.write(contribution_id, Status.OPEN)

        # Emit event
        ContributionUnassigned.emit(contribution_id.inner)

        return ()
    end

    # Validate a contribution, marking it as completed
    func validate_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId
    ):
        let (project_id) = project_access.find_contribution_project(contribution_id)
        access_control.only_lead_contributor(project_id)

        status_access.only_assigned(contribution_id)

        # Update storage
        contribution_status_.write(contribution_id, Status.COMPLETED)

        # Increase contributor contribution_count
        let (contributor_id) = contribution_contributor_.read(contribution_id)
        let (past_contributions) = past_contributions_.read(contributor_id)
        past_contributions_.write(contributor_id, past_contributions + 1)

        # Emit event
        ContributionValidated.emit(contribution_id.inner)

        return ()
    end

    # Modify a contribution count required
    func modify_gate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId, gate : felt
    ):
        let (project_id) = project_access.find_contribution_project(contribution_id)
        access_control.only_lead_contributor(project_id)

        status_access.only_open(contribution_id)

        # Update storage
        contribution_gate_.write(contribution_id, gate)

        # Emit event
        ContributionGateChanged.emit(contribution_id.inner, gate)

        return ()
    end

    # Claim (self-assign) a contributor to a contribution
    func claim_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId, contributor_id : Uint256
    ):
        let (project_id) = project_access.find_contribution_project(contribution_id)
        access_control.only_project_member(project_id)

        internal.assign_contributor_to_contribution(contribution_id, contributor_id)

        # Emit event
        ContributionClaimed.emit(contribution_id.inner, contributor_id)

        return ()
    end

    #
    # Read Only
    #

    # Get the contribution details
    func contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId
    ) -> (contribution : Contribution):
        let (contribution) = contribution_access.build(contribution_id)
        return (contribution)
    end

    # Get the number of past contributions for a given contributor
    func past_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contributor_id : Uint256
    ) -> (num_contributions : felt):
        let (num_contributions) = past_contributions_.read(contributor_id)
        return (num_contributions)
    end

    # Retrieve all contributions
    func all_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        contributions_len : felt, contributions : Contribution*
    ):
        alloc_locals
        let (local contribution_count) = contribution_count_.read()
        let (contributions : Contribution*) = alloc()
        let (contributions_len) = internal.fetch_contribution_loop(
            contribution_count, contributions
        )
        return (contributions_len, contributions)
    end

    # Retrieve all contributions in OPEN status
    func all_open_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        ) -> (contributions_len : felt, contributions : Contribution*):
        alloc_locals

        # Get all contributions
        let (contributions_len, contributions) = all_contributions()

        # Filter to keep only open ones
        let (contributions_len : felt, contributions : Contribution*) = stream.filter_struct(
            contribution_access.is_open, contributions_len, contributions, Contribution.SIZE
        )

        return (contributions_len, contributions)
    end

    # Retrieve all contributions assigned to a given contributor
    func assigned_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contributor_id : Uint256
    ) -> (contributions_len : felt, contributions : Contribution*):
        alloc_locals
        let (local contribution_count) = contribution_count_.read()
        let (contributions : Contribution*) = alloc()
        let (contributions_len) = internal.fetch_contribution_assigned_to_loop(
            contribution_count, contributions, contributor_id
        )
        return (contributions_len, contributions)
    end

    # Retrieve all contributions a given contributor is eligible to
    func eligible_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contributor_id : Uint256
    ) -> (contributions_len : felt, contributions : Contribution*):
        alloc_locals
        let (local contribution_count) = contribution_count_.read()
        let (contributions : Contribution*) = alloc()
        let (contributions_len) = internal.fetch_contribution_eligible_to_loop(
            contribution_count, contributions, contributor_id
        )
        return (contributions_len, contributions)
    end

    func add_lead_contributor_for_project{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(project_id : felt, lead_contributor_account : felt):
        access_control.grant_lead_contributor_role_for_project(project_id, lead_contributor_account)
        LeadContributorAdded.emit(project_id, lead_contributor_account)
        return ()
    end

    func remove_lead_contributor_for_project{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(project_id : felt, lead_contributor_account : felt):
        access_control.revoke_lead_contributor_role_for_project(
            project_id, lead_contributor_account
        )
        LeadContributorRemoved.emit(project_id, lead_contributor_account)
        return ()
    end

    func add_member_for_project{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, contributor_account : felt
    ):
        access_control.grant_member_role_for_project(project_id, contributor_account)
        ProjectMemberAdded.emit(project_id, contributor_account)
        return ()
    end

    func remove_member_for_project{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(project_id : felt, contributor_account : felt):
        access_control.revoke_member_role_for_project(project_id, contributor_account)
        ProjectMemberRemoved.emit(project_id, contributor_account)
        return ()
    end
end

namespace project_access:
    func assert_project_id_is_valid{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(project_id : felt):
        with_attr error_message("Contributions: Invalid project ID ({project_id})"):
            assert_nn(project_id)
            assert_not_zero(project_id)
        end
        return ()
    end

    func find_contribution_project{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId) -> (project_id : felt):
        let (project_id) = contribution_project_id.read(contribution_id)
        with_attr error_message("Contributions: Contribution does not exist"):
            assert_not_zero(project_id)
        end

        return (project_id)
    end
end

namespace gating:
    func is_contributor_eligible{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        gate : felt, contributor_id : Uint256
    ) -> (result : felt):
        alloc_locals
        let (past_contribution_count) = past_contributions_.read(contributor_id)
        let (result) = is_le(gate, past_contribution_count)
        return (result=result)
    end

    func assert_contributor_is_eligible{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId, contributor_id : Uint256):
        let (gate) = contribution_gate_.read(contribution_id)
        let (is_eligible) = is_contributor_eligible(gate, contributor_id)
        with_attr error_message("Contributions: Contributor is not eligible"):
            assert 1 = is_eligible
        end
        return ()
    end
end

namespace github_access:
    func only_new{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, issue_number : felt
    ):
        let (id) = github_ids_to_contribution_id.read(project_id, issue_number)
        let inner = id.inner
        with_attr error_message("Contributions: Contribution already exist with id {id}"):
            assert 0 = inner
        end
        return ()
    end
end

namespace status_access:
    func only_open{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId
    ):
        alloc_locals
        let (status) = contribution_status_.read(contribution_id)
        internal.status_is_not_none(status)
        with_attr error_message("Contributions: Contribution is not OPEN"):
            assert Status.OPEN = status
        end
        return ()
    end

    func only_assigned{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId
    ):
        alloc_locals
        let (status) = contribution_status_.read(contribution_id)
        internal.status_is_not_none(status)
        with_attr error_message("Contributions: Contribution is not ASSIGNED"):
            assert Status.ASSIGNED = status
        end
        return ()
    end
end

namespace contribution_access:
    func build{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId
    ) -> (contribution : Contribution):
        let (status) = contribution_status_.read(contribution_id)
        let (gate) = contribution_gate_.read(contribution_id)
        let (contributor) = contribution_contributor_.read(contribution_id)
        let (project_id) = contribution_project_id.read(contribution_id)

        let contribution = Contribution(contribution_id, project_id, status, gate, contributor)
        return (contribution)
    end

    func is_open{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution : Contribution*
    ) -> (is_open : felt):
        if contribution.status == Status.OPEN:
            return (is_open=1)
        end
        return (is_open=0)
    end
end

namespace internal:
    func status_is_not_none(status : felt):
        with_attr error_message("Contributions: Contribution does not exist"):
            assert_not_zero(status)
        end
        return ()
    end

    func fetch_contribution_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_index : felt, contributions : Contribution*
    ) -> (contributions_len : felt):
        alloc_locals

        if contribution_index == 0:
            return (0)
        end

        let (local contributions_len) = fetch_contribution_loop(
            contribution_index - 1, contributions
        )

        let contribution_id = ContributionId(contribution_index)
        let (contribution) = contribution_access.build(contribution_id)
        assert contributions[contributions_len] = contribution

        return (contributions_len=contributions_len + 1)
    end

    func fetch_contribution_assigned_to_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_index : felt, contributions : Contribution*, contributor_id : Uint256) -> (
        contributions_len : felt
    ):
        alloc_locals
        if contribution_index == 0:
            return (0)
        end

        let (contributions_len) = fetch_contribution_assigned_to_loop(
            contribution_index - 1, contributions, contributor_id
        )

        let contribution_id = ContributionId(contribution_index)
        let (local contribution) = contribution_access.build(contribution_id)

        let (same_contributor) = uint256_eq(contribution.contributor_id, contributor_id)
        if same_contributor * (1 - contribution.status + Status.ASSIGNED) == 1:
            assert contributions[contributions_len] = contribution
            tempvar contributions_len = contributions_len + 1
        else:
            tempvar contributions_len = contributions_len
        end

        return (contributions_len)
    end

    func fetch_contribution_eligible_to_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_index : felt, contributions : Contribution*, contributor_id : Uint256) -> (
        contributions_len : felt
    ):
        alloc_locals
        if contribution_index == 0:
            return (0)
        end

        let (contributions_len) = fetch_contribution_eligible_to_loop(
            contribution_index - 1, contributions, contributor_id
        )

        let contribution_id = ContributionId(contribution_index)

        let (contribution) = contribution_access.build(contribution_id)
        let (contributor_eligible) = gating.is_contributor_eligible(
            contribution.gate, contributor_id
        )
        if contributor_eligible == 1:
            assert contributions[contributions_len] = contribution
            tempvar contributions_len = contributions_len + 1
        else:
            tempvar contributions_len = contributions_len
        end

        return (contributions_len)
    end

    # Assign a contributor to a contribution without doing access role check, nor emitting any event
    func assign_contributor_to_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId, contributor_id : Uint256):
        status_access.only_open(contribution_id)
        gating.assert_contributor_is_eligible(contribution_id, contributor_id)

        # Update storage
        contribution_status_.write(contribution_id, Status.ASSIGNED)
        contribution_contributor_.write(contribution_id, contributor_id)

        return ()
    end
end
