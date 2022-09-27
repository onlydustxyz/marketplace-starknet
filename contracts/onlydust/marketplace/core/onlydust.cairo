%lang starknet

@external
func new_project(project_hash, calldata_len : felt, calldata : felt*) admin_only {
    assert is_allowed(class_hash);

    let contract = deploy(project_hash, get_contract_address())
    ProjectDeployed.emit();

    IProject.initialize_from_hash(contract, class_hash = project_hash, calldata_len, calldata);
}
