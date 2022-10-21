%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.onlydust.marketplace.library.access_control_viewer import AccessControlViewer

//
// Constants
//
const PROJECT_CONTRACT_ADDRESS = 0x00327ae4393d1f2c6cf6dae0b533efa5d58621f9ea682f07ab48540b222fd02e;
const CONTRIBUTOR_ACCOUNT_ADDRESS = 0x0735dc2018913023a5aa557b6b49013675ac4a35ce524cad94f5202d285678cd;

//
// Tests
//
@external
func test_forward_calls_to_project{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    AccessControlViewer.initialize(PROJECT_CONTRACT_ADDRESS);

    %{
        stop_mocks = [
            mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_lead_contributor", [True]),
            mock_call(ids.PROJECT_CONTRACT_ADDRESS, "is_member", [False]),
        ]
    %}

    let is_project_lead = AccessControlViewer.is_project_lead(CONTRIBUTOR_ACCOUNT_ADDRESS);
    assert TRUE = is_project_lead;

    let is_project_member = AccessControlViewer.is_project_member(CONTRIBUTOR_ACCOUNT_ADDRESS);
    assert FALSE = is_project_member;

    %{ [stop() for stop in stop_mocks] %}
    return ();
}
