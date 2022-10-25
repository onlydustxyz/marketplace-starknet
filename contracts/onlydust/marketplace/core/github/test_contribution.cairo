%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from onlydust.marketplace.test.libraries.assignment_strategy_mock import AssignmentStrategyMock
from onlydust.marketplace.core.github.contribution import initialize

@view
func test_contribution_initialization_event{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    initialize(42, 21, test_strategy_hash, 0, new ());
    %{
        expect_events(
               {"name": "GithubContributionInitialized", "data": {"project_id": 42,  "issue_number": 21}},
           )
    %}
    return ();
}

@view
func test_contribution_can_be_initialized_only_once{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    let test_strategy_hash = AssignmentStrategyMock.class_hash();
    initialize(42, 21, test_strategy_hash, 0, new ());

    %{ expect_revert() %}
    initialize(42, 21, test_strategy_hash, 0, new ());

    return ();
}
