%lang starknet

from onlydust.deathnote.core.contributions.library import Contribution

namespace assert_contribution_that:
    func repo_owner_is{contribution : Contribution}(expected : felt):
        let actual = contribution.repo_owner
        with_attr error_message(
                "Invalid contribution repository owner: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func repo_name_is{contribution : Contribution}(expected : felt):
        let actual = contribution.repo_name
        with_attr error_message(
                "Invalid contribution repository name: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func pr_id_is{contribution : Contribution}(expected : felt):
        let actual = contribution.pr_id
        with_attr error_message(
                "Invalid contribution pull request id: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func pr_status_is{contribution : Contribution}(expected : felt):
        let actual = contribution.pr_status
        with_attr error_message(
                "Invalid contribution pull reqyest status: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end
