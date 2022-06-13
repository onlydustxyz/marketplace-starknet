%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.badge_registry.library import badge_registry, UserInformation

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt):
    return badge_registry.initialize(admin)
end

#
# Externals
#

@external
func grant_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return badge_registry.grant_admin_role(address)
end

@external
func revoke_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return badge_registry.revoke_admin_role(address)
end

@external
func grant_register_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return badge_registry.grant_register_role(address)
end

@external
func revoke_register_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return badge_registry.revoke_register_role(address)
end

@external
func set_badge_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    badge_contract : felt
):
    return badge_registry.set_badge_contract(badge_contract)
end

@external
func register_github_handle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address : felt, handle : felt
):
    return badge_registry.register_github_handle(user_address, handle)
end

@external
func unregister_github_handle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address : felt, handle : felt
):
    return badge_registry.unregister_github_handle(user_address, handle)
end

#
# Views
#
@view
func badge_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    badge_contract : felt
):
    return badge_registry.badge_contract()
end

@view
func get_user_information{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address : felt
) -> (user : UserInformation):
    return badge_registry.get_user_information(user_address)
end

@view
func get_user_information_from_github_handle{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(handle : felt) -> (user : UserInformation):
    return badge_registry.get_user_information_from_github_handle(handle)
end
