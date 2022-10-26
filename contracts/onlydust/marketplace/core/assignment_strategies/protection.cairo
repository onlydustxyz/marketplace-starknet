%lang starknet

@view
func assert_can_validate(_unused) {
    with_attr error_message("YOU SHALL NOT PASS!!!") {
        assert 1 = 0;
    }
    return ();
}

@external
func on_validated(_unused) {
    return ();
}
