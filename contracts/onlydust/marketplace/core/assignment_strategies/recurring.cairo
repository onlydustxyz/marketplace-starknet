%lang starknet
//
// This strategy limit the number of assignments per contributor
// slot_count = 1 => normal contribution
// slot count > 1 => recurring contribution
// not using this strategy means infinite contribution
//

// 
// STRATEGY IMPLEMENTATION
//

@external
func initialize(slot_count) {
    // store slot max_slot_count and slot_count
}

@external
func can_assign() {
    // check slot_count > 0
}

@external
func on_assigned() {
    // decrease slot_count
}

@external
func can_unassign() {
    // check slot_count < max_slot_count
}

@external
func on_unassigned() {
    // increase slot_count
}

@external
func add_slot(add_slot_count) {
    // store slot_count += add_slot_count
    // store max_slot_count += add_slot_count
}

@external
func remove_slot(sub_slot_count) {
    // check slot_count >= sub_slot_count
    // store slot_count -= add_slot_count
    // store max_slot_count -= add_slot_count
}
