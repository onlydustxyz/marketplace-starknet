%lang starknet

import ..contributions.*

@event
func ContributionCreated(contribution_contract, repo_id, issue_number, gate) {
}

@external
func initialize(repo_id, issue_number) {
    // Gate is 0 as a Gatechanged event will be emitted by the Gated strategy at init time
    ContributionCreated.emit(get_contract_address(), repo_id, issue_number, 0)
}
