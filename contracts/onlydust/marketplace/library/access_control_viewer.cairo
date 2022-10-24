%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import get_caller_address, get_tx_info
from onlydust.marketplace.interfaces.access_control import IAccessControlViewer

//
// Storage
//
@storage_var
func access_control_viewer__project_contract_address_() -> (project_contract_address: felt) {
}

namespace AccessControlViewer {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        project_contract_address
    ) {
        access_control_viewer__project_contract_address_.write(project_contract_address);
        return ();
    }

    func is_project_lead{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account_address
    ) -> felt {
        let project_contract_address = internal.project_contract_address();
        let (is_project_lead) = IAccessControlViewer.is_lead_contributor(
            project_contract_address, contributor_account_address
        );
        return is_project_lead;
    }

    func is_account_caller_project_lead{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> felt {
        let account_caller_address = internal.get_account_caller_address();
        return is_project_lead(account_caller_address);
    }

    func assert_account_caller_is_project_lead{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
        with_attr error_message("AccessControl: Not Project Lead") {
            let is_project_lead = is_account_caller_project_lead();
            assert TRUE = is_project_lead;
        }
        return ();
    }

    func is_project_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account_address
    ) -> felt {
        let project_contract_address = internal.project_contract_address();
        let (is_project_member) = IAccessControlViewer.is_member(
            project_contract_address, contributor_account_address
        );
        return is_project_member;
    }

    func is_account_caller_project_member{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> felt {
        let account_caller_address = internal.get_account_caller_address();
        return is_project_member(account_caller_address);
    }

    func assert_account_caller_is_project_member{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() {
        with_attr error_message("AccessControl: Not Project Member") {
            let is_project_member = is_account_caller_project_member();
            assert TRUE = is_project_member;
        }
        return ();
    }
}

namespace internal {
    func project_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> felt {
        let (project_contract_address) = access_control_viewer__project_contract_address_.read();
        return project_contract_address;
    }

    func get_account_caller_address{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> felt {
        let (tx_info) = get_tx_info();
        return tx_info.account_contract_address;
    }
}
