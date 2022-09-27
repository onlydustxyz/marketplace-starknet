%lang starknet

@contract_interface
namespace IOnlyDust {
    func is_admin(account) -> bool {}

    func allow_strategy(class_hash) admin_only {}
    func disallow_strategy(class_hash) admin_only {}
    func is_allowed(class_hash) {}

    func new_project(project_hash, calldata_len : felt, calldata : felt*) admin_only {}
}
