%lang starknet

from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.contributions.github.library import Contribution

@contract_interface
namespace IGithub:
    func contribution_count(token_id : Uint256) -> (contribution_count : felt):
    end

    func contribution(token_id : Uint256, contribution_id : felt) -> (contribution : Contribution):
    end

    func add_contribution(token_id : Uint256, contribution : Contribution):
    end

    func grant_admin_role(address : felt):
    end

    func revoke_admin_role(address : felt):
    end

    func grant_feeder_role(address : felt):
    end

    func revoke_feeder_role(address : felt):
    end

    func set_registry_contract(registry_contract : felt):
    end

    func add_contribution_from_handle(handle : felt, contribution : Contribution):
    end
end
