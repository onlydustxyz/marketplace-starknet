%lang starknet

from onlydust.deathnote.core.badge_registry.library import UserInformation

@contract_interface
namespace IBadgeRegistry:
    func set_badge_contract(badge_contract : felt):
    end

    func transfer_ownership(new_owner : felt):
    end

    func register_github_handle(user_address : felt, handle : felt):
    end

    func owner() -> (owner : felt):
    end

    func badge_contract() -> (badge_contract : felt):
    end

    func get_user_information(user_address : felt) -> (user : UserInformation):
    end
end
