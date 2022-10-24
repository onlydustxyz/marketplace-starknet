%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address
from onlydust.marketplace.test.libraries.assignment_strategy_mock import AssignmentStrategyMock
from starkware.cairo.common.alloc import alloc

from onlydust.marketplace.core.github.contribution import initialize

@view
func test_contribution_initialization_event{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let test_strategy_hash = AssignmentStrategyMock.class_hash();
    let repo_id = 42;
    let issue_number = 21;

    let (local calldata) = alloc();
    assert calldata[0] = repo_id;
    assert calldata[1] = issue_number;
    assert calldata[2] = test_strategy_hash;
    assert calldata[3] = 0;

    initialize(calldata_len=4, calldata=calldata);

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "GithubContributionInitialized", "data": {"project_id": ids.repo_id,  "issue_number": ids.issue_number}},
           )
    %}
    return ();
}

@view
func test_contribution_can_be_initialized_only_once{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    let test_strategy_hash = AssignmentStrategyMock.class_hash();

    let (local calldata) = alloc();
    assert calldata[0] = 42;
    assert calldata[1] = 21;
    assert calldata[2] = test_strategy_hash;
    assert calldata[3] = 0;

    initialize(calldata_len=4, calldata=calldata);

    %{ expect_revert() %}

    initialize(calldata_len=4, calldata=calldata);
    return ();
}
