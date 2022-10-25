%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from onlydust.marketplace.core.github.contribution import initialize

@view
func test_contribution_initialization_event{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    initialize(42, 21);
    %{ expect_events({"name": "GithubContributionInitialized", "data": {"project_id": 42,  "issue_number": 21}}) %}

    return ();
}
