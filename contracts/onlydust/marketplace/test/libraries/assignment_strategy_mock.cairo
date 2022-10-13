%lang starknet

from starkware.cairo.common.bool import TRUE, FALSE
from starkware.cairo.common.cairo_builtins import HashBuiltin

@storage_var
func assignment_strategy__test__function_calls(function_selector: felt) -> (count: felt) {
}

@storage_var
func assignment_strategy__test__revert_requested() -> (revert_requested: felt) {
}

@external
func request_revert{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    assignment_strategy__test__revert_requested.write(TRUE);
    return ();
}

@external
@raw_input
@raw_output
func __default__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    selector: felt, calldata_size: felt, calldata: felt*
) -> (retdata_size: felt, retdata: felt*) {
    let (count) = assignment_strategy__test__function_calls.read(selector);
    assignment_strategy__test__function_calls.write(selector, count + 1);

    let (revert_requested) = assignment_strategy__test__revert_requested.read();
    with_attr error_message("Revert requested") {
        assert FALSE = revert_requested;
    }

    return (retdata_size=0, retdata=new ());
}
