%lang starknet

@contract_interface
namespace IOnlyDust {
    func is_admin(account) -> (res: felt) {
    }

    func allow_strategy(class_hash) {
        // admin_only
    }
    func disallow_strategy(class_hash) {
        // admin_only
    }
    func is_allowed(class_hash) -> (res: felt) {
    }

    func new_project(project_hash, calldata_len: felt, calldata: felt*) {
        // admin_only
    }
}
