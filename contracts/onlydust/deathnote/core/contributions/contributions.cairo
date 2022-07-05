%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin

from onlydust.deathnote.core.contributions.library import contributions, Contribution

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt):
    return contributions.initialize(admin)
end

#
# Views
#
@view
func contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contribution_id : felt
) -> (contribution : Contribution):
    return contributions.contribution(contribution_id)
end

#
# Externals
#

@external
func grant_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return contributions.grant_admin_role(address)
end

@external
func revoke_admin_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return contributions.revoke_admin_role(address)
end

@external
func grant_feeder_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return contributions.grant_feeder_role(address)
end

@external
func revoke_feeder_role{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    address : felt
):
    return contributions.revoke_feeder_role(address)
end

@external
func new_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contribution : Contribution
):
    return contributions.new_contribution(contribution)
end
