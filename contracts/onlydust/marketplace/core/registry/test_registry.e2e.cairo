%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.interfaces.registry import IRegistry, UserInformation
from onlydust.marketplace.test.libraries.user import assert_user_that

const ADMIN = 'admin';
const REGISTERER = 'register';
const PROFILE = 'profile';
const CONTRIBUTOR = 'contributor';
const GITHUB_ID = 'github_user';

//
// Tests
//
@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    tempvar registry;
    %{
        context.registry = deploy_contract("./contracts/onlydust/marketplace/core/registry/registry.cairo", [ids.ADMIN]).contract_address 
        ids.registry = context.registry
        stop_prank = start_prank(ids.ADMIN, ids.registry)
    %}
    IRegistry.set_profile_contract(registry, PROFILE);
    IRegistry.grant_registerer_role(registry, REGISTERER);
    %{ stop_prank() %}

    return ();
}

@view
func test_registry_e2e{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let (registry) = registry_access.deployed();

    with registry {
        %{ mock_call(ids.PROFILE, 'mint', [0, 0]) %}
        let (user) = registry_access.register_github_identifier(CONTRIBUTOR, GITHUB_ID);
    }

    with user {
        assert_user_that.profile_contract_is(PROFILE);
        assert_user_that.contributor_id_is(Uint256(0, 0));
        assert_user_that.github_identifier_is(GITHUB_ID);
    }

    with registry {
        let (user) = registry_access.unregister_github_identifier(CONTRIBUTOR, GITHUB_ID);
    }

    with user {
        assert_user_that.profile_contract_is(PROFILE);
        assert_user_that.contributor_id_is(Uint256(0, 0));
        assert_user_that.github_identifier_is(0);
    }

    return ();
}

//
// Libraries
//
namespace registry_access {
    func deployed() -> (registry: felt) {
        tempvar registry;
        %{ ids.registry = context.registry %}
        return (registry,);
    }

    func register_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, registry: felt
    }(contributor: felt, identifier: felt) -> (user: UserInformation) {
        %{ stop_prank = start_prank(ids.REGISTERER, ids.registry) %}
        IRegistry.register_github_identifier(registry, contributor, identifier);
        %{ stop_prank() %}

        let (user) = IRegistry.get_user_information_from_github_identifier(registry, identifier);
        return (user,);
    }

    func unregister_github_identifier{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, registry: felt
    }(contributor: felt, identifier: felt) -> (user: UserInformation) {
        %{ stop_prank = start_prank(ids.REGISTERER, ids.registry) %}
        IRegistry.unregister_github_identifier(registry, contributor, identifier);
        %{ stop_prank() %}

        let (user) = IRegistry.get_user_information(registry, contributor);
        return (user,);
    }
}
