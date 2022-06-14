%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import get_caller_address

from onlydust.deathnote.interfaces.badge_registry import IBadgeRegistry

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
    member NONE : felt
    member OPEN : felt
    member REVIEW : felt
    member MERGED : felt
end

#
# Structs
#
struct Contribution:
    member repo_owner : felt
    member repo_name : felt
    member pr_id : felt
    member pr_status : felt
end

#
# Storage
#
@storage_var
func contribution_from_hash_(contribution_hash : felt) -> (contribution : Contribution):
end

@storage_var
func contribution_owner_from_hash_(contribution_hash : felt) -> (token_id : Uint256):
end

@storage_var
func contribution_hash_from_index_(token_id : Uint256, index : felt) -> (contribution_hash : felt):
end

@storage_var
func contribution_count_(token_id : Uint256) -> (count : felt):
end

@storage_var
func registry_contract_() -> (registry_contract : felt):
end

#
# Functions
#
namespace github:
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
        with_attr error_message("Github: Cannot self renounce to ADMIN role"):
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

    # Set the Badge Registry contract
    func set_registry_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        registry_contract : felt
    ):
        internal.assert_only_admin()
        registry_contract_.write(registry_contract)
        return ()
    end

    # Add a contribution for a given token id
    func add_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, contribution : Contribution
    ):
        alloc_locals

        internal.assert_valid(contribution)
        internal.assert_only_feeder()  # Only check role if input contribution is valid

        let (local contribution_hash) = internal.hash(contribution)
        let (exists) = internal.exists(contribution_hash)
        if exists == 0:
            internal.add(contribution_hash, token_id, contribution)  # New contribution, add it
        else:
            internal.assert_owner(contribution_hash, token_id)
            internal.update_data(contribution_hash, contribution)  # Existing contribution, update only the data
        end

        return ()
    end

    func add_contribution_from_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(handle : felt, contribution : Contribution):
        let (registry_contract) = registry_contract_.read()
        with_attr error_message("Github: Registry cannot be 0"):
            assert_not_zero(registry_contract)
        end

        let (user) = IBadgeRegistry.get_user_information_from_github_handle(
            registry_contract, handle
        )
        return add_contribution(user.token_id, contribution)
    end

    # Get the contribution count for a given token id
    func contribution_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ) -> (contribution_count : felt):
        let (contribution_count) = contribution_count_.read(token_id)
        return (contribution_count)
    end

    # Get the contribution details
    func contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, contribution_id : felt
    ) -> (contribution : Contribution):
        internal.assert_valid_contribution_id(token_id, contribution_id)

        let (contribution_hash) = contribution_hash_from_index_.read(token_id, contribution_id)
        let (contribution) = contribution_from_hash_.read(contribution_hash)
        return (contribution)
    end
end

namespace internal:
    func assert_only_feeder{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Github: FEEDER role required"):
            AccessControl._only_role(Role.FEEDER)
        end

        return ()
    end

    func assert_only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Github: ADMIN role required"):
            AccessControl._only_role(Role.ADMIN)
        end

        return ()
    end

    func assert_not_caller{syscall_ptr : felt*}(address : felt):
        let (caller_address) = get_caller_address()
        assert_not_zero(caller_address - address)
        return ()
    end

    func assert_valid_contribution_id{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(token_id : Uint256, contribution_id : felt):
        with_attr error_message("Github: Invalid contribution id ({contribution_id})"):
            assert_nn(contribution_id)

            let (contribution_count) = contribution_count_.read(token_id)
            assert_lt(contribution_id, contribution_count)
        end
        return ()
    end

    func assert_valid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution : Contribution
    ):
        assert_valid_pr_status(contribution.pr_status)
        return ()
    end

    func assert_valid_pr_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pr_status : felt
    ):
        with_attr error_message("Github: Invalid PR status ({pr_status})"):
            assert_nn(pr_status)
            assert_not_zero(pr_status - Status.NONE)
            assert_lt(pr_status, Status.SIZE)
        end
        return ()
    end

    func hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution : Contribution
    ) -> (contribution_hash : felt):
        let (h) = hash2{hash_ptr=pedersen_ptr}(contribution.repo_owner, contribution.repo_name)
        let (h) = hash2{hash_ptr=pedersen_ptr}(h, contribution.pr_id)
        return (h)
    end

    func exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt
    ) -> (exists : felt):
        let (contribution) = contribution_from_hash_.read(contribution_hash)
        let (exists) = is_not_zero(contribution.pr_status - Status.NONE)
        return (exists)
    end

    func add{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt, token_id : Uint256, contribution : Contribution
    ):
        update_data(contribution_hash, contribution)
        contribution_owner_from_hash_.write(contribution_hash, token_id)

        let (contribution_count) = contribution_count_.read(token_id)
        contribution_hash_from_index_.write(token_id, contribution_count, contribution_hash)
        contribution_count_.write(token_id, contribution_count + 1)

        return ()
    end

    func update_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt, contribution : Contribution
    ):
        contribution_from_hash_.write(contribution_hash, contribution)

        return ()
    end

    func assert_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt, token_id : Uint256
    ):
        let (owner) = contribution_owner_from_hash_.read(contribution_hash)
        with_attr error_message("Github: Cannot change the owner of a given contribution"):
            assert owner = token_id
        end

        return ()
    end
end
