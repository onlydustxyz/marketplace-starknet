%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin

//
// Events
//
@event
func GithubContributionInitialized(project_id: felt, issue_number: felt) {
}

//
// Init
//

@external
func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    repo_id: felt, issue_number: felt
) {
    GithubContributionInitialized.emit(repo_id, issue_number);

    return ();
}
