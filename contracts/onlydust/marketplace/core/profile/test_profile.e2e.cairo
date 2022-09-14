%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.interfaces.profile import IProfile

const ADMIN = 'admin';
const REGISTRY = 'registry';
const CONTRIBUTOR = 'contributor';

//
// Tests
//
@view
func __setup__{syscall_ptr: felt*, range_check_ptr}() {
    tempvar profile_contract;
    %{
        context.profile_contract = deploy_contract("./contracts/onlydust/marketplace/core/profile/profile.cairo", [ids.ADMIN]).contract_address
        ids.profile_contract = context.profile_contract
        stop_prank = start_prank(ids.ADMIN, ids.profile_contract)
    %}
    IProfile.grant_minter_role(profile_contract, REGISTRY);
    %{ stop_prank() %}

    return ();
}

@view
func test_profile_e2e{syscall_ptr: felt*, range_check_ptr}() {
    let (profile) = profile_access.deployed();

    with profile {
        assert_that.name_is('Death Note Profile');
        assert_that.symbol_is('DNP');

        let (token_id) = profile_access.mint(CONTRIBUTOR);
        assert_that.owner_is(token_id, CONTRIBUTOR);
    }

    return ();
}

//
// Libraries
//
namespace profile_access {
    func deployed() -> (profile_contract: felt) {
        tempvar profile_contract;
        %{ ids.profile_contract = context.profile_contract %}
        return (profile_contract,);
    }

    func mint{syscall_ptr: felt*, range_check_ptr, profile: felt}(contributor: felt) -> (
        token_id: Uint256
    ) {
        %{ stop_prank = start_prank(ids.REGISTRY,  ids.profile) %}
        let (token_id) = IProfile.mint(profile, contributor);
        %{ stop_prank() %}
        return (token_id,);
    }
}

namespace assert_that {
    func name_is{syscall_ptr: felt*, range_check_ptr, profile: felt}(expected: felt) {
        alloc_locals;
        let (local actual) = IProfile.name(profile);

        with_attr error_message("Invalid name: expected {expected}, actual {actual}") {
            assert expected = actual;
        }
        return ();
    }

    func symbol_is{syscall_ptr: felt*, range_check_ptr, profile: felt}(expected: felt) {
        alloc_locals;
        let (local actual) = IProfile.symbol(profile);

        with_attr error_message("Invalid symbol: expected {expected}, actual {actual}") {
            assert expected = actual;
        }
        return ();
    }

    func owner_is{syscall_ptr: felt*, range_check_ptr, profile: felt}(
        token_id: Uint256, expected: felt
    ) {
        alloc_locals;
        let (local actual) = IProfile.ownerOf(profile, token_id);

        with_attr error_message("Invalid owner: expected {expected}, actual {actual}") {
            assert expected = actual;
        }
        return ();
    }
}
