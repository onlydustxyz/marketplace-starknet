%lang starknet

@contract_interface
namespace IAssignmentStrategy {
    func initialize(calldata_len, calldata: felt*) {
    }

    func assert_can_assign(contributor_account) {
    }
    func on_assigned(contributor_account) {
    }

    func assert_can_unassign(contributor_account) {
    }
    func on_unassigned(contributor_account) {
    }

    func assert_can_validate(contributor_account) {
    }
    func on_validated(contributor_account) {
    }
}
