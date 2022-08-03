%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from openzeppelin.upgrades.library import Proxy

from onlydust.deathnote.core.contributions.library import contributions, Contribution

# DO NOT REMOVE THOSE IMPORTS
# They are mandatory to make this contract upgradable and migratable
from onlydust.deathnote.library.migration_library import (
    migratable_proxy,
    implementation,
    proxy_admin,
    set_implementation,
    set_implementation_with_migration,
    set_proxy_admin,
)

#
# Constructor
#

@external
func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    proxy_admin : felt
):
    migratable_proxy.initializer(proxy_admin)
    contributions.initialize(proxy_admin)
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
