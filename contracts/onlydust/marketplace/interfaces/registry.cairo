%lang starknet

from onlydust.marketplace.core.registry.library import UserInformation

@contract_interface
namespace IRegistry {
    func set_profile_contract(profile_contract: felt) {
    }

    func grant_admin_role(address: felt) {
    }

    func revoke_admin_role(address: felt) {
    }

    func grant_registerer_role(address: felt) {
    }

    func revoke_registerer_role(address: felt) {
    }

    func register_github_identifier(user_address: felt, identifier: felt) {
    }

    func unregister_github_identifier(user_address: felt, identifier: felt) {
    }

    func profile_contract() -> (profile_contract: felt) {
    }

    func get_user_information(user_address: felt) -> (user: UserInformation) {
    }

    func get_user_information_from_github_identifier(identifier: felt) -> (user: UserInformation) {
    }
}
