%lang starknet

@contract_interface
namespace IAssignmentStrategy {
    func can_assign(contributor_account) -> (res: felt) {
    }
    func on_assigned(contributor_account) {
    }

    func can_unassign(contributor_account) -> (res: felt) {
    }
    func on_unassigned(contributor_account) {
    }

    func can_validate(contributor_account) -> (res: felt) {
    }
    func on_validated(contributor_account) {
    }
}

// Example of contribution creation with strategies

// Gated (past_contributions_count_required = 2)
// Sequential (max_parallel_count = 1)
// Recurring (slot_count = 30)

// starknet invoke --abi project.json --contract_address $project_contract --function new_contribution --inputs \
//     $github_contribution_hash $composite_hash \
//     6 \
//     $github_contribution_hash 2 11111 235 // github repo id and issue number
//     $access_control_hash 1 $project_contract \
//     $gated_hash 1 2 \
//     $sequential_hash 1 1 \
//     $recurring_hash 1 30 \
//     $composite_hash 4 $access_control $gated_hash $sequential_hash $recurring_hash

// starknet invoke --abi gated.json --contract_address $contribution_contract --function set_past_contributions_count_required --inputs 2
