%lang starknet

import ..project.*

@event
func GithubProjectInitialized(repo_id) {
}

@external
func initialize(repo_id) {
    GithubProjectInitialized.emit(repo_id)
}
