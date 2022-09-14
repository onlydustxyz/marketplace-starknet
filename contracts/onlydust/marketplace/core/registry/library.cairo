%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address

from onlydust.marketplace.interfaces.profile import IProfile

from openzeppelin.access.accesscontrol.library import AccessControl

//
// Enums
//
struct Role {
    // Keep ADMIN role first of this list as 0 is the default admin value to manage roles in AccessControl library
    ADMIN: felt,  // ADMIN role, can assign/revoke roles
    REGISTERER: felt,  // REGISTERER role, can register/unregister users
}

//
// Structs
//
struct Identifiers {
    github: felt,
}

struct UserInformation {
    profile_contract: felt,
    contributor_id: Uint256,
    identifiers: Identifiers,
}

//
// Events
//
@event
func GithubIdentifierRegistered(profile_contract: felt, contributor_id: Uint256, identifier: felt) {
}

@event
func GithubIdentifierUnregistered(
    profile_contract: felt, contributor_id: Uint256, identifier: felt
) {
}

//
// Storage
//
@storage_var
func profile_contract_() -> (address: felt) {
}

@storage_var
func users_(address: felt) -> (user: UserInformation) {
}

@storage_var
func github_identifiers_to_user_address_(identifier: felt) -> (user_address: felt) {
}

namespace registry {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
        AccessControl.initializer();
        AccessControl._grant_role(Role.ADMIN, admin);
        return ();
    }

    // Grant the ADMIN role to a given address
    func grant_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.grant_role(Role.ADMIN, address);
        return ();
    }

    // Revoke the ADMIN role from a given address
    func revoke_admin_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        with_attr error_message("Registry: Cannot self renounce to ADMIN role") {
            internal.assert_not_caller(address);
        }
        AccessControl.revoke_role(Role.ADMIN, address);
        return ();
    }

    // Grant the REGISTERER role to a given address
    func grant_registerer_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.grant_role(Role.REGISTERER, address);
        return ();
    }

    // Revoke the REGISTERER role from a given address
    func revoke_registerer_role{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) {
        AccessControl.revoke_role(Role.REGISTERER, address);
        return ();
    }

    func set_profile_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        profile_contract: felt
    ) {
        internal.assert_only_admin();
        profile_contract_.write(profile_contract);
        return ();
    }

    func profile_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        profile_contract: felt
    ) {
        let (profile_contract) = profile_contract_.read();
        return (profile_contract,);
    }

    func get_user_information{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        user_address: felt
    ) -> (user: UserInformation) {
        let (user) = users_.read(user_address);

        with_attr error_message("Registry: Unregistered user") {
            assert_not_zero(user.profile_contract);
        }

        return (user,);
    }

    func get_user_information_from_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(identifier: felt) -> (user: UserInformation) {
        let (user_address) = github_identifiers_to_user_address_.read(identifier);
        let (user) = get_user_information(user_address);
        return (user,);
    }

    func register_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(user_address: felt, identifier: felt) {
        internal.assert_only_register();

        with_attr error_message("Registry: Github identifier already registered") {
            let (address) = github_identifiers_to_user_address_.read(identifier);
            assert 0 = address;
        }

        let (user) = users_.read(user_address);
        with user {
            internal.mint_profile_if_needed(user_address);
            internal.set_github_identifier(identifier);
        }

        users_.write(user_address, user);
        github_identifiers_to_user_address_.write(identifier, user_address);

        return ();
    }

    func unregister_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(user_address: felt, identifier: felt) {
        internal.assert_only_register();

        let (user) = users_.read(user_address);
        with_attr error_message(
                "Registry: The address does not match the github identifier provided") {
            assert identifier = user.identifiers.github;
        }
        with user {
            internal.remove_github_identifier();
        }

        users_.write(user_address, user);
        github_identifiers_to_user_address_.write(identifier, 0);

        return ();
    }
}

namespace internal {
    func assert_only_admin{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        with_attr error_message("Registry: ADMIN role required") {
            AccessControl.assert_only_role(Role.ADMIN);
        }

        return ();
    }

    func assert_only_register{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        with_attr error_message("Registry: REGISTERER role required") {
            AccessControl.assert_only_role(Role.REGISTERER);
        }

        return ();
    }

    func assert_not_caller{syscall_ptr: felt*}(address: felt) {
        let (caller_address) = get_caller_address();
        assert_not_zero(caller_address - address);
        return ();
    }

    func mint_profile_if_needed{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, user: UserInformation
    }(address: felt) {
        let (profile_contract) = profile_contract_.read();
        with_attr error_message("Registry: Missing Profile contract") {
            assert_not_zero(profile_contract);
        }

        if (profile_contract == user.profile_contract) {
            return ();  // user profile contract is up-to-date, no need to mint
        }

        // Update user with minted token
        let (contributor_id) = IProfile.mint(profile_contract, address);
        let user = UserInformation(
            profile_contract=profile_contract,
            contributor_id=contributor_id,
            identifiers=user.identifiers,
        );

        return ();
    }

    func set_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, user: UserInformation
    }(identifier: felt) {
        GithubIdentifierRegistered.emit(user.profile_contract, user.contributor_id, identifier);

        let user = UserInformation(
            profile_contract=user.profile_contract,
            contributor_id=user.contributor_id,
            identifiers=Identifiers(github=identifier),
        );
        return ();
    }

    func remove_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, user: UserInformation
    }() {
        GithubIdentifierUnregistered.emit(
            user.profile_contract, user.contributor_id, user.identifiers.github
        );

        let user = UserInformation(
            profile_contract=user.profile_contract,
            contributor_id=user.contributor_id,
            identifiers=Identifiers(github=0),
        );
        return ();
    }
}
