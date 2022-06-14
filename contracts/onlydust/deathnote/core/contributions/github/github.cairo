%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.github.library import github, Contribution

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt):
    return github.initialize(admin)
end

#
# Views
#
@view
func contribution_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256
) -> (contribution_count : felt):
    return github.contribution_count(token_id)
end

@view
func contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, contribution_id : felt
) -> (contribution : Contribution):
    return github.contribution(token_id, contribution_id)
end

#
# Externals
#

@external
func grant_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return github.grant_admin_role(address)
end

@external
func revoke_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return github.revoke_admin_role(address)
end

@external
func grant_feeder_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return github.grant_feeder_role(address)
end

@external
func revoke_feeder_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return github.revoke_feeder_role(address)
end

@external
func add_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    token_id : Uint256, contribution : Contribution
):
    return github.add_contribution(token_id, contribution)
end

@external
func set_registry_contract{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    registry_contract : felt
):
    return github.set_registry_contract(registry_contract)
end

@external
func add_contribution_from_identifier{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(identifier : felt, contribution : Contribution):
    return github.add_contribution_from_identifier(identifier, contribution)
end
