%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

@storage_var
func I_HAVE_BEEN_HACKED() -> (res: felt) {
}

@view
func assert_can_validate(_unused) {
    with_attr error_message("YOU SHALL NOT PASS!!!") {
        assert 1 = 0;
    }
    return ();
}

@external
func on_validated{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(_unused) {
    I_HAVE_BEEN_HACKED.write(1);
    return ();
}

@view
func hacked{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    with_attr error_message("Try again :-)") {
        let (hacked) = I_HAVE_BEEN_HACKED.read();
        assert 1 = hacked;
    }

    return ();
}
