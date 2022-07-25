%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.upgrades.library import Proxy

from onlydust.deathnote.core.contributions.library import contributions, Contribution

#
# Constructor
#
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(admin : felt):
    return contributions.initialize(admin)
end

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proxy_admin : felt
):
    Proxy.initializer(proxy_admin)
    constructor(proxy_admin)
    return ()
end

#
# Proxy / Upgrades
#

@view
func implementation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    address : felt
):
    let (address) = Proxy.get_implementation_hash()
    return (address)
end

@view
func proxy_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    admin : felt
):
    let (admin) = Proxy.get_admin()
    return (admin)
end

@external
func set_implementation{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_implementation_hash : felt
):
    Proxy.assert_only_admin()
    Proxy._set_implementation_hash(new_implementation_hash)
    return ()
end

@external
func set_proxy_admin{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    new_admin : felt
):
    Proxy.assert_only_admin()
    Proxy._set_admin(new_admin)
    return ()
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

@view
func past_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contributor_id : Uint256
) -> (num_contributions : felt):
    return contributions.past_contributions(contributor_id)
end

@view
func all_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
    contributions_len : felt, contributions : Contribution*
):
    return contributions.all_contributions()
end

@view
func all_open_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> (contributions_len : felt, contributions : Contribution*):
    return contributions.all_open_contributions()
end

@view
func assigned_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contributor_id : Uint256
) -> (contributions_len : felt, contributions : Contribution*):
    return contributions.assigned_contributions(contributor_id)
end

@view
func eligible_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contributor_id : Uint256
) -> (contributions_len : felt, contributions : Contribution*):
    return contributions.eligible_contributions(contributor_id)
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
    id : felt, project_id : felt, contribution_count_required : felt, validator_account : felt
) -> (contribution : Contribution):
    return contributions.new_contribution(
        id, project_id, contribution_count_required, validator_account
    )
end

@external
func assign_contributor_to_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(contribution_id : felt, contributor_id : Uint256):
    return contributions.assign_contributor_to_contribution(contribution_id, contributor_id)
end

@external
func unassign_contributor_from_contribution{
    syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
}(contribution_id : felt):
    return contributions.unassign_contributor_from_contribution(contribution_id)
end

@external
func validate_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    contribution_id : felt
):
    return contributions.validate_contribution(contribution_id)
end
