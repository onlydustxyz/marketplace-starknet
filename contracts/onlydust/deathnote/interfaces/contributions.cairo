%lang starknet

from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.contributions.library import Contribution

@contract_interface
namespace IContributions:
    func new_contribution(contribution : Contribution):
    end

    func contribution(contribution_id : felt) -> (contribution : Contribution):
    end

    func all_contributions() -> (contributions_len : felt, contributions : Contribution*):
    end

    func grant_admin_role(address : felt):
    end

    func revoke_admin_role(address : felt):
    end

    func grant_feeder_role(address : felt):
    end

    func revoke_feeder_role(address : felt):
    end
end
