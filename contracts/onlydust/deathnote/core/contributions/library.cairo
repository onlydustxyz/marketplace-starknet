%lang starknet

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
end

#
# Storage
#
@storage_var
func contributions_(contribution_id : felt) -> (contribution : Contribution):
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
            contribution_access.only_status(Status.OPEN)
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

    func only_status{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }(status : felt):
        with_attr error_message(
                "Contributions: Invalid status ({contribution.status}), expected ({status})"):
            assert status = contribution.status
        end
        return ()
    end

    func store{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        contribution : Contribution,
    }():
        contributions_.write(contribution.id, contribution)
        return ()
    end

    func read{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_id : felt
    ) -> (contribution : Contribution):
        let (contribution) = contributions_.read(contribution_id)
        return (contribution)
    end
end
