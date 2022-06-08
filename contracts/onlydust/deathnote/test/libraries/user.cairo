%lang starknet

from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.badge_registry.library import badge_registry, UserInformation

namespace assert_user_that:
    func badge_contract_is{user : UserInformation}(expected : felt):
        let actual = user.badge_contract
        with_attr error_message(
                "Invalid user badge contract: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func token_id_is{user : UserInformation}(expected : Uint256):
        let actual = user.token_id
        with_attr error_message("Invalid user token id: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func github_handle_is{user : UserInformation}(expected : felt):
        let actual = user.handles.github
        with_attr error_message("Invalid user github handle: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end
