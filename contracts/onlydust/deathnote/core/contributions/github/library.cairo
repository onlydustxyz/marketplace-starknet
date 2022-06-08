%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt, assert_not_zero
from starkware.cairo.common.math_cmp import is_not_zero
from starkware.cairo.common.hash import hash2

from openzeppelin.access.ownable import Ownable

#
# Enums
#
struct Status:
    member NONE : felt
    member OPEN : felt
    member REVIEW : felt
    member MERGED : felt
end

#
# Structs
#
struct Contribution:
    member repo_owner : felt
    member repo_name : felt
    member pr_id : felt
    member pr_status : felt
end

#
# Storage
#
@storage_var
func contribution_from_hash_(contribution_hash : felt) -> (contribution : Contribution):
end

@storage_var
func contribution_owner_from_hash_(contribution_hash : felt) -> (token_id : Uint256):
end

@storage_var
func contribution_hash_from_index_(token_id : Uint256, index : felt) -> (contribution_hash : felt):
end

@storage_var
func contribution_count_(token_id : Uint256) -> (count : felt):
end

#
# Functions
#
namespace github:
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt
    ):
        Ownable.initializer(owner)
        return ()
    end

    func owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        owner : felt
    ):
        return Ownable.owner()
    end

    func transfer_ownership{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        new_owner : felt
    ):
        Ownable.transfer_ownership(new_owner)
        return ()
    end

    # Add a contribution for a given token id
    func add_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, contribution : Contribution
    ):
        alloc_locals

        internal.assert_valid(contribution)
        Ownable.assert_only_owner()  # Only check owner if input contribution is valid

        let (local contribution_hash) = internal.hash(contribution)
        let (exists) = internal.exists(contribution_hash)
        if exists == 0:
            internal.add(contribution_hash, token_id, contribution)  # New contribution, add it
        else:
            internal.assert_owner(contribution_hash, token_id)
            internal.update_data(contribution_hash, contribution)  # Existing contribution, update only the data
        end

        return ()
    end

    # Get the contribution count for a given token id
    func contribution_count{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256
    ) -> (contribution_count : felt):
        let (contribution_count) = contribution_count_.read(token_id)
        return (contribution_count)
    end

    # Get the contribution details
    func contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_id : Uint256, contribution_id : felt
    ) -> (contribution : Contribution):
        internal.assert_valid_contribution_id(token_id, contribution_id)

        let (contribution_hash) = contribution_hash_from_index_.read(token_id, contribution_id)
        let (contribution) = contribution_from_hash_.read(contribution_hash)
        return (contribution)
    end
end

namespace internal:
    func assert_valid_contribution_id{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    }(token_id : Uint256, contribution_id : felt):
        with_attr error_message("Github: Invalid contribution id ({contribution_id})"):
            assert_nn(contribution_id)

            let (contribution_count) = contribution_count_.read(token_id)
            assert_lt(contribution_id, contribution_count)
        end
        return ()
    end

    func assert_valid{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution : Contribution
    ):
        assert_valid_pr_status(contribution.pr_status)
        return ()
    end

    func assert_valid_pr_status{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        pr_status : felt
    ):
        with_attr error_message("Github: Invalid PR status ({pr_status})"):
            assert_nn(pr_status)
            assert_not_zero(pr_status - Status.NONE)
            assert_lt(pr_status, Status.SIZE)
        end
        return ()
    end

    func hash{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution : Contribution
    ) -> (contribution_hash : felt):
        let (h) = hash2{hash_ptr=pedersen_ptr}(contribution.repo_owner, contribution.repo_name)
        let (h) = hash2{hash_ptr=pedersen_ptr}(h, contribution.pr_id)
        return (h)
    end

    func exists{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt
    ) -> (exists : felt):
        let (contribution) = contribution_from_hash_.read(contribution_hash)
        let (exists) = is_not_zero(contribution.pr_status - Status.NONE)
        return (exists)
    end

    func add{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt, token_id : Uint256, contribution : Contribution
    ):
        update_data(contribution_hash, contribution)
        contribution_owner_from_hash_.write(contribution_hash, token_id)

        let (contribution_count) = contribution_count_.read(token_id)
        contribution_hash_from_index_.write(token_id, contribution_count, contribution_hash)
        contribution_count_.write(token_id, contribution_count + 1)

        return ()
    end

    func update_data{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt, contribution : Contribution
    ):
        contribution_from_hash_.write(contribution_hash, contribution)

        return ()
    end

    func assert_owner{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_hash : felt, token_id : Uint256
    ):
        let (owner) = contribution_owner_from_hash_.read(contribution_hash)
        with_attr error_message("Github: Cannot change the owner of a given contribution"):
            assert owner = token_id
        end

        return ()
    end
end
