%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from onlydust.deathnote.interfaces.badge import IBadge

from onlydust.deathnote.library.accesscontrol import AccessControl  # TODO change to OZ implem when 0.2.0 is released

#
# Enums
#
struct Role:
    # Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    member ADMIN : felt  # ADMIN role, can assign/revoke roles
    member REGISTER : felt  # REGISTER role, can register/unregister users
end

#
# Structs
#
struct Handles:
    member github : felt
end

struct UserInformation:
    member badge_contract : felt
    member token_id : Uint256
    member handles : Handles
end

#
# Events
#
@event
func GithubHandleRegistered(badge_contract : felt, token_id : Uint256, handle : felt):
end

@event
func GithubHandleUnregistered(badge_contract : felt, token_id : Uint256, handle : felt):
end

#
# Storage
#
@storage_var
func badge_contract_() -> (address : felt):
end

@storage_var
func users_(address : felt) -> (user : UserInformation):
end

@storage_var
func github_handles_to_user_address_(handle : felt) -> (user_address : felt):
end

namespace badge_registry:
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
        with_attr error_message("Badge Registry: Cannot self renounce to ADMIN role"):
            internal.assert_not_caller(address)
        end
        AccessControl.revoke_role(Role.ADMIN, address)
        return ()
    end

    # Grant the REGISTER role to a given address
    func grant_register_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        AccessControl.grant_role(Role.REGISTER, address)
        return ()
    end

    # Revoke the REGISTER role from a given address
    func revoke_register_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt
    ):
        AccessControl.revoke_role(Role.REGISTER, address)
        return ()
    end

    func set_badge_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        badge_contract : felt
    ):
        internal.assert_only_admin()
        badge_contract_.write(badge_contract)
        return ()
    end

    func badge_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        badge_contract : felt
    ):
        let (badge_contract) = badge_contract_.read()
        return (badge_contract)
    end

    func get_user_information{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        user_address : felt
    ) -> (user : UserInformation):
        let (user) = users_.read(user_address)

        with_attr error_message("Badge Registry: Unregistered user"):
            assert_not_zero(user.badge_contract)
        end

        return (user)
    end

    func get_user_information_from_github_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(handle : felt) -> (user : UserInformation):
        let (user_address) = github_handles_to_user_address_.read(handle)
        let (user) = get_user_information(user_address)
        return (user)
    end

    func register_github_handle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        user_address : felt, handle : felt
    ):
        internal.assert_only_register()

        with_attr error_message("Badge Registry: Github handle already registered"):
            let (address) = github_handles_to_user_address_.read(handle)
            assert 0 = address
        end

        let (user) = users_.read(user_address)
        with user:
            internal.mint_badge_if_needed(user_address)
            internal.set_github_handle(handle)
        end

        users_.write(user_address, user)
        github_handles_to_user_address_.write(handle, user_address)

        return ()
    end

    func unregister_github_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(user_address : felt, handle : felt):
        internal.assert_only_register()

        let (user) = users_.read(user_address)
        with_attr error_message(
                "Badge Registry: The address does not match the github handle provided"):
            assert handle = user.handles.github
        end
        with user:
            internal.remove_github_handle()
        end

        users_.write(user_address, user)
        github_handles_to_user_address_.write(handle, 0)

        return ()
    end
end

namespace internal:
    func assert_only_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Badge Registry: ADMIN role required"):
            AccessControl._only_role(Role.ADMIN)
        end

        return ()
    end

    func assert_only_register{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        with_attr error_message("Badge Registry: REGISTER role required"):
            AccessControl._only_role(Role.REGISTER)
        end

        return ()
    end

    func assert_not_caller{syscall_ptr : felt*}(address : felt):
        let (caller_address) = get_caller_address()
        assert_not_zero(caller_address - address)
        return ()
    end

    func mint_badge_if_needed{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, user : UserInformation
    }(address : felt):
        let (badge_contract) = badge_contract_.read()
        with_attr error_message("Badge Registry: Missing Badge contract"):
            assert_not_zero(badge_contract)
        end

        if badge_contract == user.badge_contract:
            return ()  # user badge contract is up-to-date, no need to mint
        end

        # Update user with minted token
        let (token_id) = IBadge.mint(badge_contract, address)
        let user = UserInformation(
            badge_contract=badge_contract, token_id=token_id, handles=user.handles
        )

        return ()
    end

    func set_github_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, user : UserInformation
    }(handle : felt):
        GithubHandleRegistered.emit(user.badge_contract, user.token_id, handle)

        let user = UserInformation(
            badge_contract=user.badge_contract,
            token_id=user.token_id,
            handles=Handles(github=handle),
        )
        return ()
    end

    func remove_github_handle{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr, user : UserInformation
    }():
        GithubHandleUnregistered.emit(user.badge_contract, user.token_id, user.handles.github)

        let user = UserInformation(
            badge_contract=user.badge_contract, token_id=user.token_id, handles=Handles(github=0)
        )
        return ()
    end
end
