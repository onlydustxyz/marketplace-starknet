from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_lt
from starkware.starknet.common.syscalls import library_call

namespace Class {
    func initialize_from_hash{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        class_hash: felt, calldata_len: felt, calldata: felt*
    ) {
        const INITIALIZE_SELECTOR = 0x79dc0da7c54b95f10aa182ad0a46400db63156920adb65eca2654c0945a463;  // initialize
        library_call(class_hash, INITIALIZE_SELECTOR, calldata_len, calldata);
        return ();
    }

    func initialize_from_calldata{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        calldata_len: felt, calldata: felt*
    ) {
        if (calldata_len == 0) {
            return ();
        }

        with_attr error_message("Not enough arguments") {
            assert_lt(1, calldata_len);
        }

        let arg_class_hash = calldata[0];
        let arg_calldata_len = calldata[1];
        initialize_from_hash(arg_class_hash, arg_calldata_len, calldata + 2);

        return initialize_from_calldata(
            calldata_len=calldata_len - arg_calldata_len - 2,
            calldata=calldata + arg_calldata_len + 2,
        );
    }
}
