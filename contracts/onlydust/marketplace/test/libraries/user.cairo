%lang starknet

from starkware.cairo.common.uint256 import Uint256

from onlydust.marketplace.core.registry.library import UserInformation

namespace assert_user_that {
    func profile_contract_is{user: UserInformation}(expected: felt) {
        let actual = user.profile_contract;
        with_attr error_message(
                "Invalid user profile contract: expected {expected}, actual {actual}") {
            assert expected = actual;
        }
        return ();
    }

    func contributor_id_is{user: UserInformation}(expected: Uint256) {
        let actual = user.contributor_id;
        with_attr error_message("Invalid contributor id: expected {expected}, actual {actual}") {
            assert expected = actual;
        }
        return ();
    }

    func github_identifier_is{user: UserInformation}(expected: felt) {
        let actual = user.identifiers.github;
        with_attr error_message(
                "Invalid user github identifier: expected {expected}, actual {actual}") {
            assert expected = actual;
        }
        return ();
    }
}
