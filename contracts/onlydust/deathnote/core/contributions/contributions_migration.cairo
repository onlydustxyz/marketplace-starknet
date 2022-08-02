%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

from onlydust.deathnote.core.contributions.library import contributions, Contribution

@storage_var
func contributions_(contribution_id : felt) -> (contribution : Contribution):
end

@external
func migrate{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    const CONTRIBUTION_ID = 481932781000051

    let (contribution) = contributions_.read(CONTRIBUTION_ID)

    assert CONTRIBUTION_ID = contribution.id
    assert 2 = contribution.contribution_count_required

    let new_contribution = Contribution(
        id=contribution.id,
        project_id=contribution.project_id,
        status=contribution.status,
        contributor_id=contribution.contributor_id,
        contribution_count_required=0,
        validator_account=contribution.validator_account,
    )

    contributions_.write(contribution.id, new_contribution)

    let (new_contribution) = contributions_.read(contribution.id)

    assert CONTRIBUTION_ID = new_contribution.id
    assert 0 = new_contribution.contribution_count_required

    return ()
end
