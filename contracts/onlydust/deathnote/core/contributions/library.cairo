%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address

from onlydust.deathnote.library.accesscontrol import AccessControl  # TODO change to OZ implem when 0.2.0 is released

#
# Enums
#
struct Role:
    # Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    member ADMIN : felt  # ADMIN role, can assign/revoke roles
    member FEEDER : felt  # FEEDER role, can add a contribution
end

struct Status:
    member OPEN : felt
    member ASSIGNED : felt
    member COMPLETED : felt
    member ABANDONED : felt
end

#
# Structs
#
struct Contribution:
    member id : felt
    member project_id : felt
    member status : felt
    member contributor_id : Uint256
end

#
# Storage
#
@storage_var
func contributions_(contribution_id : felt) -> (contribution : Contribution):
end

@storage_var
func indexed_contribution_ids_(contribution_index : felt) -> (contribution_id : felt):
end

@storage_var
func contribution_count_() -> (contribution_count : felt):
end

#
# Functions
#
namespace contributions:
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

    # Add a contribution for a given token id
    func new_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution : Contribution
    ):
        alloc_locals

        internal.only_feeder()

        with contribution:
            contribution_access.assert_valid()
            contribution_access.only_open()
            contribution_access.store()
        end

        return ()
    end

    # Get the contribution details
    func contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : felt
    ) -> (contribution : Contribution):
        let (contribution) = contribution_access.read(contribution_id)
        return (contribution)
    end

    # Retrieve all contributions
    func all_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        contributions_len : felt, contributions : Contribution*
    ):
        alloc_locals
        let (local contribution_count) = contribution_count_.read()
        let (contributions : Contribution*) = alloc()
        internal.fetch_contribution_loop(contribution_count, contributions)
        return (contributions_len=contribution_count, contributions=contributions)
    end

    # Assign a contributor to a contribution
    func assign_contributor_to_contribution{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(contribution_id : felt, contributor_id : Uint256):
        internal.only_feeder()

        let (contribution) = contribution_access.read(contribution_id)
        with contribution:
            contribution_access.only_open()
<<<<<<< HEAD
            let contribution = Contribution(
                contribution.id, contribution.project_id, Status.ASSIGNED, contributor_id
            )
=======
        end

        let contribution = Contribution(
            contribution.id, contribution.project_id, Status.ASSIGNED, contributor_id
        )
        with contribution:
>>>>>>> d20543b (:sparkles: store the contributor_id inside the contribution struct)
            contribution_access.store()
        end

        return ()
    end
end

namespace internal:
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
    ):
        if contribution_index == 0:
            return ()
        end

        let (contribution_id) = indexed_contribution_ids_.read(contribution_index - 1)
        let (contribution) = contribution_access.read(contribution_id)
        assert [contributions] = contribution

        return fetch_contribution_loop(contribution_index - 1, contributions + Contribution.SIZE)
    end
end

namespace contribution_access:
    func assert_valid{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        assert_valid_status()
        assert_valid_id()
        assert_valid_project_id()
        return ()
    end

    func assert_valid_status{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        with_attr error_message(
                "Contributions: Invalid contribution status ({contribution.status})"):
            assert_nn(contribution.status)
            assert_lt(contribution.status, Status.SIZE)
        end
        return ()
    end

    func assert_valid_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        with_attr error_message("Contributions: Invalid contribution ID ({contribution.id})"):
            assert_nn(contribution.id)
            assert_not_zero(contribution.id)
        end
        return ()
    end

    func assert_valid_project_id{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        with_attr error_message("Contributions: Invalid project ID ({contribution.project_id})"):
            assert_nn(contribution.project_id)
            assert_not_zero(contribution.project_id)
        end
        return ()
    end

    func only_open{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        with_attr error_message("Contributions: Contribution is not OPEN"):
            assert Status.OPEN = contribution.status
        end
        return ()
    end

    func store{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        increase_contribution_count_if_needed()
        contributions_.write(contribution.id, contribution)
        return ()
    end

    func increase_contribution_count_if_needed{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        let (already_exists) = exists(contribution.id)
        if already_exists == 0:
            let (contribution_count) = contribution_count_.read()
            indexed_contribution_ids_.write(contribution_count, contribution.id)
            contribution_count_.write(contribution_count + 1)
            return ()
        end

        return ()
    end

    func read{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : felt
    ) -> (contribution : Contribution):
        let (contribution) = contributions_.read(contribution_id)
        with_attr error_message("Contributions: Contribution does not exist"):
            assert_not_zero(contribution.id)
        end

        return (contribution)
    end

    func exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : felt
    ) -> (exists : felt):
        let (contribution) = contributions_.read(contribution_id)
        let (exists) = is_not_zero(contribution.id)
        return (exists)
    end
end
