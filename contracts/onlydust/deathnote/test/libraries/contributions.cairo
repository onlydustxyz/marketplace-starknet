%lang starknet

from onlydust.deathnote.core.contributions.library import Contribution

namespace assert_contribution_that:
    func id_is{contribution : Contribution}(expected : felt):
        let actual = contribution.id
        with_attr error_message("Invalid contribution ID: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func project_id_is{contribution : Contribution}(expected : felt):
        let actual = contribution.project_id
        with_attr error_message("Invalid project ID: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end

    func status_is{contribution : Contribution}(expected : felt):
        let actual = contribution.status
        with_attr error_message(
                "Invalid contribution status: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end
