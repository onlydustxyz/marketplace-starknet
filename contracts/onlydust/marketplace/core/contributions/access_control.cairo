%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from openzeppelin.access.accesscontrol import AccessControl

#
# Enums
#
struct Role:
    # Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    member ADMIN : felt  # can assign/revoke roles
    member FEEDER : felt  # can interact with all contributions
    member LEAD_CONTRIBUTOR : felt # can add interact with contributions on its project
end

#
# Storage
#
@storage_var
func role_member_by_contributor_and_key_(role : felt, key : felt, contributor_id : Uint256) -> (is_member : felt):
end

#
# Functions
#
namespace access_control:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        admin : felt
    ):
        AccessControl.initializer()
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

    func only_feeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Contributions: FEEDER role required"):
            AccessControl.assert_only_role(Role.FEEDER)
        end

        return ()
    end

    func only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Contributions: ADMIN role required"):
            AccessControl.assert_only_role(Role.ADMIN)
        end

        return ()
    end

    func grant_lead_contributor_role_for_project{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, contributor_id : Uint256):
        only_admin()
        role_member_by_contributor_and_key_.write(Role.LEAD_CONTRIBUTOR, project_id, contributor_id, 1)
        return ()
    end

    func revoke_lead_contributor_role_for_project{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, contributor_id : Uint256):
        only_admin()
        role_member_by_contributor_and_key_.write(Role.LEAD_CONTRIBUTOR, project_id, contributor_id, 0)
        return ()
    end

    func only_lead_contributor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        project_id : felt, contributor_id : Uint256):
        let (is_member) = role_member_by_contributor_and_key_.read(Role.LEAD_CONTRIBUTOR, project_id, contributor_id)
        with_attr error_message("Contributions: LEAD_CONTRIBUTOR role required"):
            assert_not_zero(is_member)
        end
        return()
    end
end

namespace internal:
    func assert_not_caller{syscall_ptr : felt*}(address : felt):
        let (caller_address) = get_caller_address()
        assert_not_zero(caller_address - address)
        return ()
    end
end
