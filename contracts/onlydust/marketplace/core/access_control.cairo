%lang starknet

// func is_lead_contributor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     contributor_account: felt
// ) -> (result: felt) {
//     alloc_locals;
//     let (project_contract) = contribution_project_contract_.read();
//     let (is_lead: felt) = IProject.is_lead_contributor(project_contract, contributor_account);
//     return (result=is_lead);
// }

// func is_project_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     contributor_account: felt
// ) -> (result: felt) {
//     alloc_locals;
//     let (project_contract) = contribution_project_contract_.read();
//     let (is_member: felt) = IProject.is_member(project_contract, contributor_account);
//     return (result=is_member);
// }

// func assert_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
//     contributor_account: felt
// ) {
//     alloc_locals;
//     let caller = internal.get_account_caller_address();

// let (is_lead) = is_lead_contributor(caller);
//     if (is_lead == 1) {
//         return ();
//     }

// let (is_member) = is_project_member(caller);
//     if (is_member == 1 and contributor_account == caller) {
//         return ();
//     }

// with_attr error_message("Contribution: LEAD_CONTRIBUTOR or PROJECT_MEMBER role required") {
//         assert 1 = 0;
//     }
//     return ();
// }

// func only_lead_contributor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
//     alloc_locals;
//     let caller = internal.get_account_caller_address();
//     let (is_lead) = is_lead_contributor(caller);

// with_attr error_message("Contribution: LEAD_CONTRIBUTOR role required") {
//         assert 1 = is_lead;
//     }
//     return ();
// }

// @external
// func modify_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(gate: felt) {
//     access_control.only_lead_contributor();
//     status_access.only_open();

// // Update storage
//     contribution_gate_.write(gate);

// // Emit event
//     let (contribution_address) = get_contract_address();
//     ContributionGateChanged.emit(contribution_address, gate);

// return ();
// }

// namespace internal {
//     func get_account_caller_address{
//         syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
//     }() -> felt {
//         let (tx_info: TxInfo*) = get_tx_info();
//         return tx_info.account_contract_address;
//     }
// }
