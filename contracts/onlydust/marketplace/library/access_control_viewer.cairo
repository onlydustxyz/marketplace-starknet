%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.onlydust.marketplace.interfaces.access_control import IAccessControlViewer

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
        let (project_contract_address) = internal.project_contract_address();
        let (is_project_lead) = IAccessControlViewer.is_lead_contributor(
            project_contract_address, contributor_account_address
        );
        return is_project_lead;
    }

    func is_project_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account_address
    ) -> felt {
        let (project_contract_address) = internal.project_contract_address();
        let (is_project_member) = IAccessControlViewer.is_member(
            project_contract_address, contributor_account_address
        );
        return is_project_member;
    }
}

namespace internal {
    func project_contract_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (project_contract_address: felt) {
        return access_control_viewer__project_contract_address_.read();
    }
}
