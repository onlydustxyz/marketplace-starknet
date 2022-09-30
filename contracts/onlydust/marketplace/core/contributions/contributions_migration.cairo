%lang starknet
//
//
// Code not compiled and not used
// Preparation work for https://www.notion.so/onlydust/Clean-up-contributor_id-from-codebase-e54f6214552e4604bad9d67c08778800
// Migrate the past_contributions_count(contributor_id) => past_contributions_count(contributor_account) for all legacy ids
//
//

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256, uint256_add, split_64
from starkware.cairo.common.math_cmp import is_le, is_not_zero, is_nn
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_contract_address

from onlydust.stream.default_implementation import stream

const STAGING_CONTRIBUTIONS_CONTRACT = 0x04aa3b2b258388a58ed429795ab56a9cd9613152755ec317f5c6bee2294e2264;
const STAGING_PROFILE_CONTRACT = 0x02c14d6aa7db2bac800fcfa3217e98d340351da192531f3f7839b89a4af7e8a7;
const STAGING_CONTRIBUTORS_COUNT = 8;

const PROD_CONTRIBUTIONS_CONTRACT = 0x011d60f34d8e7b674833d86aa85afbe234baad95ae6ca3d9cb5c4bcd164b7358;
const PROD_PROFILE_CONTRACT = 0x004176872b71583cb9bc3671db28f26e7f426a7c0764613a0838bb99ef373aa6;
const PROD_CONTRIBUTORS_COUNT = 0x10d;

@storage_var
func past_contributions_(contributor_id: Uint256) -> (contribution_count: felt) {
}

@contract_interface
namespace IProfile {
    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }
}

@external
func migrate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let count = contributors_count();
    loop(count, Uint256(0, 0));
    return ();
}

func loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    remaining_count: felt, contributor_id: Uint256
) {
    if (remaining_count == 0) {
        return ();
    }
    migrate_past_contributions_count(contributor_id);

    let (next_contributor_id: Uint256, _: felt) = uint256_add(contributor_id, Uint256(1, 0));

    loop(remaining_count - 1, next_contributor_id);
    return ();
}

func migrate_past_contributions_count{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}(contributor_id: Uint256) {
    let profile = profile_contract();
    let (contributor_account) = IProfile.ownerOf(profile, contributor_id);
    let (count) = past_contributions_.read(contributor_id);
    past_contributions_.write(Uint256(contributor_account, 0), count);
    return ();
}

func is_production{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    let (this) = get_contract_address();
    if (this == PROD_CONTRIBUTIONS_CONTRACT) {
        return 1;
    }

    return 0;
}

func is_staging{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    let (this) = get_contract_address();
    if (this == STAGING_CONTRIBUTIONS_CONTRACT) {
        return 1;
    }

    return 0;
}

func profile_contract{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    if (is_production() == 1) {
        return PROD_PROFILE_CONTRACT;
    }

    if (is_staging() == 1) {
        return STAGING_PROFILE_CONTRACT;
    }

    with_attr error_message("Neither in prod nor staging") {
        assert 1 = 0;
    }

    return 0;
}

func contributors_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
    if (is_production() == 1) {
        return PROD_CONTRIBUTORS_COUNT;
    }

    if (is_staging() == 1) {
        return STAGING_CONTRIBUTORS_COUNT;
    }

    with_attr error_message("Neither in prod nor staging") {
        assert 1 = 0;
    }

    return 0;
}
