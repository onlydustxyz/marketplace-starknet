%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt, assert_le, assert_not_zero, sign
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address

from onlydust.marketplace.library.accesscontrol import AccessControl  # TODO change to OZ implem when 0.2.0 is released
from onlydust.stream.default_implementation import stream

#
# Enums
#
struct Role:
    # Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    member ADMIN : felt  # ADMIN role, can assign/revoke roles
    member FEEDER : felt  # FEEDER role, can add a contribution
end

struct DeprecatedStatus:
    member OPEN : felt
    member ASSIGNED : felt
    member COMPLETED : felt
    member ABANDONED : felt
end

struct Status:
    member NONE: felt
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
    member contribution_count_required : felt
    member validator_account : felt
end

struct ContributionId:
    member inner: felt
end

struct Contribution:
    member id: ContributionId
    member project_id : felt
    member status: felt
    member gate: felt
    member contributor_id: Uint256
end

#
# Events
#
@event
func ContributionCreated(contribution_id: felt, project_id: felt, issue_number: felt, gate: felt):
end

@event
func ContributionAssigned(contribution_id: felt, contributor_id: Uint256):
end

@event
func ContributionUnassigned(contribution_id: felt):
end

@event
func ContributionValidated(contribution_id: felt):
end

@event
func ContributionGateChanged(contribution_id: felt, gate: felt):
end

#
# Storage
#
@storage_var
func contribution_project_id(contribution_id : ContributionId) -> (project_id: felt):
end

@storage_var
func contribution_status_(contribution_id : ContributionId) -> (status : felt):
end

@storage_var
func contribution_contributor_(contribution_id : ContributionId) -> (contributor_id: Uint256):
end

@storage_var
func contribution_gate_(contribution_id : ContributionId) -> (gate: felt):
end

@storage_var
func contribution_count_() -> (contribution_count : felt):
end

@storage_var
func past_contributions_(contributor_id : Uint256) -> (contribution_count : felt):
end

@storage_var
func github_ids_to_contribution_id(project_id : felt, issue_numer: felt) -> (contribution_id: ContributionId):
end


#
# Functions
#
namespace contributions:
    #
    # Access Control
    #

    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        admin : felt
    ):
        AccessControl.constructor()
        AccessControl._grant_role(Role.ADMIN, admin)
        return ()
    end

    # Grant the ADMIN role to a given address
    func grant_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        AccessControl.grant_role(Role.ADMIN, address)
        return ()
    end

    # Revoke the ADMIN role from a given address
    func revoke_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        with_attr error_message("Contributions: Cannot self renounce to ADMIN role"):
            internal.assert_not_caller(address)
        end
        AccessControl.revoke_role(Role.ADMIN, address)
        return ()
    end

    # Grant the FEEDER role to a given address
    func grant_feeder_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        AccessControl.grant_role(Role.FEEDER, address)
        return ()
    end

    # Revoke the FEEDER role from a given address
    func revoke_feeder_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        AccessControl.revoke_role(Role.FEEDER, address)
        return ()
    end

    #
    # Write
    #

    # Add a contribution for a given token id
    func new_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        old_composite_id : felt, project_id : felt, contribution_count_required : felt
    ) -> (contribution : Contribution):
        alloc_locals

        internal.only_feeder()
        
        with_attr error_message("Contributions: Invalid project ID ({project_id})"):
            assert_nn(project_id)
            assert_not_zero(project_id)
        end

        with_attr error_message("Contributions: Invalid contribution count required"):
            let (count_sign) = sign(contribution_count_required)
            assert 0 = count_sign * (1 - count_sign)
            assert_nn(contribution_count_required)
        end
        
        let issue_number = old_composite_id - project_id * 1000000
        with_attr error_message("Contributions: invalid id {old_composite_id}, must be project_id * 1000000 + issue_number"):
            assert_nn(issue_number)
            assert_not_zero(issue_number)
        end
        github_access.only_new(project_id, issue_number)

        let (contribution_count) = contribution_count_.read()
        let new_count = contribution_count + 1
        let id = ContributionId(new_count)

        # Update storage
        contribution_status_.write(id, Status.OPEN)
        contribution_gate_.write(id, contribution_count_required)
        contribution_project_id.write(id, project_id)
        contribution_count_.write(new_count)
        github_ids_to_contribution_id.write(project_id, issue_number, id)
        
        ContributionCreated.emit(new_count, project_id, issue_number, contribution_count_required)
        
        let contribution = Contribution(
            id,
            project_id,
            Status.OPEN,
            contribution_count_required,
            Uint256(0, 0),
        )

        return (contribution)
    end

    # Assign a contributor to a contribution
    func assign_contributor_to_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId, contributor_id : Uint256):
        internal.only_feeder()
        
        status_access.only_open(contribution_id)
        gating.assert_contributor_is_eligible(contribution_id, contributor_id)
        
        # Update storage
        contribution_status_.write(contribution_id, Status.ASSIGNED)
        contribution_contributor_.write(contribution_id, contributor_id)

        # Emit event
        ContributionAssigned.emit(contribution_id.inner, contributor_id)

        return ()
    end

    # Unassign a contributor from a contribution
    func unassign_contributor_from_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : ContributionId):
        internal.only_feeder()

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
        internal.only_feeder()

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
    func modify_contribution_count_required{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : ContributionId, contribution_count_required : felt
    ):
        internal.only_feeder()

        status_access.only_open(contribution_id) 
        
        # Update storage
        contribution_gate_.write(contribution_id, contribution_count_required)

        # Emit event
        ContributionGateChanged.emit(contribution_id.inner, contribution_count_required)
        
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

end

namespace gating:
    func is_contributor_eligible{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        gate: felt, contributor_id : Uint256
    ) -> (result : felt):
        alloc_locals
        let (past_contribution_count) = past_contributions_.read(contributor_id)
        let (result) = is_le(gate, past_contribution_count)
        return (result=result)
    end
    
     func assert_contributor_is_eligible{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(
        contribution_id: ContributionId, contributor_id : Uint256
    ):
        let (gate) = contribution_gate_.read(contribution_id)
        let (is_eligible) = is_contributor_eligible(gate, contributor_id)
        with_attr error_message("Contributions: Contributor is not eligible"):
            assert 1 = is_eligible
        end
        return ()
    end    
end

namespace github_access:
    func only_new{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(project_id: felt, issue_number: felt):
        let (id) = github_ids_to_contribution_id.read(project_id, issue_number)
        let inner = id.inner
        with_attr error_message("Contributions: Contribution already exist with id {id}"):
            assert 0 = inner
        end
        return ()
    end
    
end

namespace status_access:
    func only_open{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(contribution_id : ContributionId):
        alloc_locals
        let (status) = contribution_status_.read(contribution_id)
        internal.status_is_not_none(status)
        with_attr error_message("Contributions: Contribution is not OPEN"):
            assert Status.OPEN = status
        end
        return ()
    end
    
    func only_assigned{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(contribution_id : ContributionId):
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
    func build{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
    }(contribution_id : ContributionId) -> (contribution: Contribution):
        let (status) = contribution_status_.read(contribution_id)
        let (gate) = contribution_gate_.read(contribution_id)
        let (contributor) = contribution_contributor_.read(contribution_id)
        let (project_id) = contribution_project_id.read(contribution_id)
        
        let contribution = Contribution(
            contribution_id,
            project_id,
            status,
            gate,
            contributor
        )
        return (contribution)
    end

    func is_open{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution: Contribution* 
    ) -> (is_open : felt):
        if contribution.status == Status.OPEN:
            return (is_open=1)
        end
        return (is_open=0)
    end
end

namespace internal:
    func status_is_not_none(status: felt):
        with_attr error_message("Contributions: Contribution does not exist"):
            assert_not_zero(status)
        end
        return ()
    end

    func only_feeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Contributions: FEEDER role required"):
            AccessControl._only_role(Role.FEEDER)
        end

        return ()
    end

    func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Contributions: ADMIN role required"):
            AccessControl._only_role(Role.ADMIN)
        end

        return ()
    end

    func assert_not_caller{syscall_ptr : felt*}(address : felt):
        let (caller_address) = get_caller_address()
        assert_not_zero(caller_address - address)
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
end