%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math_cmp import is_le, is_not_zero, is_nn
from starkware.cairo.common.alloc import alloc

from onlydust.marketplace.core.contributions.library import contributions, DeprecatedContribution, DeprecatedStatus, ContributionCreated, Status, ContributionAssigned, ContributionValidated, ContributionId
from onlydust.stream.default_implementation import stream


@storage_var
func contributions_(old_contribution_id : felt) -> (contribution : DeprecatedContribution):
end

@storage_var
func contribution_status_(contribution_id : ContributionId) -> (status : felt):
end

@storage_var
func contribution_contributor_(contribution_id : ContributionId) -> (contributor_id: Uint256):
end

@storage_var
func contribution_gate_(contribution_id : ContributionId) -> (gate: felt):
end

@storage_var
func contribution_project_id(contribution_id : ContributionId) -> (project_id: felt):
end

@storage_var
func contribution_count_() -> (contribution_count : felt):
end

@storage_var
func github_ids_to_contribution_id(project_id : felt, issue_numer: felt) -> (contribution_id: ContributionId):
end


@storage_var
func indexed_contribution_ids_(contribution_index : felt) -> (old_contribution_id : felt):
end


@external
func migrate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        let (contributions_len, contribs) = all_deprecated_contributions()
        
        stream.foreach_struct(migrate_single_contribution, contributions_len, contribs, DeprecatedContribution.SIZE)
    
        return ()
end

func migrate_single_contribution{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(index: felt, el : DeprecatedContribution*):
    let (is_id_invalid_format) =  is_le(el[0].id, 1000000)
    if is_id_invalid_format == 1:
        return()
    end

    let issue_number = el[0].id - el[0].project_id * 1000000
    let (not_null) = is_nn(issue_number)
    let (not_zero) = is_not_zero(issue_number)
    if not_null * not_zero == 0:
        return ()
    end

    let id = ContributionId(index+1)

    contribution_status_.write(id, el[0].status +1)
    contribution_gate_.write(id, el[0].gate)
    contribution_project_id.write(id, el[0].project_id)

    github_ids_to_contribution_id.write(el[0].project_id, issue_number, id)
    ContributionCreated.emit(index+1, el[0].project_id, issue_number, el[0].gate)

    if el[0].status == DeprecatedStatus.OPEN:
        return ()        
    end
    
    contribution_contributor_.write(id, el[0].contributor_id)
    ContributionAssigned.emit(index+1, el[0].contributor_id)
    
    if el[0].status == DeprecatedStatus.ASSIGNED:
        return ()        
    end
    
    ContributionValidated.emit(index+1)

    # Status.ABANDONED is not used atm so no need to handle it

    return ()
end

func all_deprecated_contributions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        contributions_len : felt, contributions : DeprecatedContribution*
    ):
        alloc_locals
        let (local contribution_count) = contribution_count_.read()
        let (contributions : DeprecatedContribution*) = alloc()
        let (contributions_len) = fetch_contribution_loop(
            contribution_count, contributions
        )
        return (contributions_len, contributions)
    end
    
func fetch_contribution_loop{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        contribution_index : felt, contributions : DeprecatedContribution*
    ) -> (contributions_len : felt):
        alloc_locals

        if contribution_index == 0:
            return (0)
        end

        let (local contributions_len) = fetch_contribution_loop(
            contribution_index - 1, contributions
        )

        let (contribution_id) = indexed_contribution_ids_.read(contribution_index - 1)
        let (contribution) = contributions_.read(contribution_id)
        assert contributions[contributions_len] = contribution

        return (contributions_len=contributions_len + 1)
    end