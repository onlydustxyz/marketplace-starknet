%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from onlydust.marketplace.core.contributions.library import contributions, Contribution, ContributionCreated, Status, ContributionAssigned, ContributionValidated
from onlydust.stream.default_implementation import stream


@storage_var
func contributions_(contribution_id : felt) -> (contribution : Contribution):
end

@external
func migrate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
        let (contributions_len, contribs) = contributions.all_contributions()
        
        stream.foreach_struct(emit_contribution_events, contributions_len, contribs, Contribution.SIZE)
        
        return ()
end

func emit_contribution_events{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_index: felt, el : Contribution*):
    ContributionCreated.emit(el[0].project_id, el[0].id, el[0].contribution_count_required)

    if el[0].status == Status.OPEN:
        return ()        
    end
    
    ContributionAssigned.emit(el[0].id, el[0].contributor_id)
    
    if el[0].status == Status.ASSIGNED:
        return ()        
    end
    
    ContributionValidated.emit(el[0].id)

    # Status.ABANDONED is not used atm so no need to handle it

    return ()
end