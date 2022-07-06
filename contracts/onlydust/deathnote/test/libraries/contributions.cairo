%lang starknet

from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.core.contributions.library import Contribution, Status

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

    func contributor_is{contribution : Contribution}(expected : Uint256):
        let actual = contribution.contributor_id
        with_attr error_message("Invalid contributor: expected {expected}, actual {actual}"):
            assert expected = actual
        end
        return ()
    end
end

namespace contribution_access:
    func create(contribution_id : felt, project_id : felt) -> (contribution : Contribution):
        return (Contribution(contribution_id, project_id, Status.OPEN, Uint256(0, 0), 0))
    end

    func create_with_gate(contribution_id : felt, project_id : felt, threshold : felt) -> (
        contribution : Contribution
    ):
        return (Contribution(contribution_id, project_id, Status.OPEN, Uint256(0, 0), threshold))
    end
end
