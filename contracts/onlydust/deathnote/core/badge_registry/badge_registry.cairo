%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.badge_registry.library import badge_registry, UserInformation

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(owner : felt):
    return badge_registry.initialize(owner)
end

#
# Externals
#
@external
func set_badge_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    badge_contract : felt
):
    return badge_registry.set_badge_contract(badge_contract)
end

@external
func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_owner : felt
):
    return badge_registry.transfer_ownership(new_owner)
end

@external
func register_github_handle{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address : felt, handle : felt
):
    return badge_registry.register_github_handle(user_address, handle)
end

#
# Views
#
@view
func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (owner : felt):
    return badge_registry.owner()
end

@view
func get_badge_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    badge_contract : felt
):
    return badge_registry.get_badge_contract()
end

@view
func get_user_information{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    user_address : felt
) -> (user : UserInformation):
    return badge_registry.get_user_information(user_address)
end
