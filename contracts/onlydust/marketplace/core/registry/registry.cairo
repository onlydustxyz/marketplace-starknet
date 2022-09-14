%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.marketplace.core.registry.library import registry, UserInformation

//
// Constructor
//
@constructor
func constructor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
    return registry.initialize(admin);
}

//
// Externals
//

@external
func grant_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    return registry.grant_admin_role(address);
}

@external
func revoke_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    return registry.revoke_admin_role(address);
}

@external
func grant_registerer_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    return registry.grant_registerer_role(address);
}

@external
func revoke_registerer_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    address: felt
) {
    return registry.revoke_registerer_role(address);
}

@external
func set_profile_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    profile_contract: felt
) {
    return registry.set_profile_contract(profile_contract);
}

@external
func register_github_identifier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user_address: felt, identifier: felt
) {
    return registry.register_github_identifier(user_address, identifier);
}

@external
func unregister_github_identifier{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user_address: felt, identifier: felt
) {
    return registry.unregister_github_identifier(user_address, identifier);
}

//
// Views
//
@view
func profile_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
    profile_contract: felt
) {
    return registry.profile_contract();
}

@view
func get_user_information{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    user_address: felt
) -> (user: UserInformation) {
    return registry.get_user_information(user_address);
}

@view
func get_user_information_from_github_identifier{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(identifier: felt) -> (user: UserInformation) {
    return registry.get_user_information_from_github_identifier(identifier);
}
