%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import library_call

//
// Common functions to be imported to any contribution implementation to be usable by OnlyDust platform
//

@external
func initialize_from_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    class_hash, calldata_len, calldata: felt*
) {
    const INITIALIZE_SELECTOR = 0x79dc0da7c54b95f10aa182ad0a46400db63156920adb65eca2654c0945a463;  // initialize()
    library_call(class_hash, INITIALIZE_SELECTOR, calldata_len, calldata);

    return ();
}
