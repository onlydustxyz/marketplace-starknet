%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import FALSE
from starkware.cairo.common.uint256 import Uint256, uint256_eq
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_nn, assert_lt, assert_le, assert_not_zero, sign
from starkware.cairo.common.math_cmp import is_not_zero, is_le
from starkware.cairo.common.hash import hash2
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    deploy,
    get_tx_info,
    TxInfo,
)

from onlydust.stream.default_implementation import stream
from onlydust.marketplace.core.contributions.access_control import (
    access_control,
    LeadContributorAdded,
    LeadContributorRemoved,
    ProjectMemberAdded,
    ProjectMemberRemoved,
)
from onlydust.marketplace.interfaces.contribution import IContribution

@contract_interface
namespace IGithubContribution {
    func initialize(calldata_len: felt, calldata: felt*) {
    }

    func change_gate(gate: felt) {
    }

    func close() {
    }
}

//
// Enums
//
struct DeprecatedStatus {
    OPEN: felt,
    ASSIGNED: felt,
    COMPLETED: felt,
    ABANDONED: felt,
}

struct Status {
    NONE: felt,
    OPEN: felt,
    ASSIGNED: felt,
    COMPLETED: felt,
    ABANDONED: felt,
}

//
// Structs
//
struct DeprecatedContribution {
    id: felt,
    project_id: felt,
    status: felt,
    contributor_id: Uint256,
    gate: felt,
    validator_account: felt,
}

struct ContributionId {
    inner: felt,
}

struct Contribution {
    id: ContributionId,
    project_id: felt,
    status: felt,
    gate: felt,
    contributor_id: Uint256,
}

//
// Events
//
@event
func ContributionDeployed(contract_address) {
}

@event
func ContributionCreated(contribution_id: felt, project_id: felt, issue_number: felt, gate: felt) {
}

@event
func ContributionDeleted(contribution_id: felt) {
}

@event
func ContributionAssigned(contribution_id: felt, contributor_id: Uint256) {
}

@event
func ContributionUnassigned(contribution_id: felt) {
}

@event
func ContributionClaimed(contribution_id: felt, contributor_id: Uint256) {
}

@event
func ContributionValidated(contribution_id: felt) {
}

@event
func ContributionGateChanged(contribution_id: felt, gate: felt) {
}

//
// Storage
//
@storage_var
func contributions_deploy_salt_() -> (salt: felt) {
}

@storage_var
func contribution_project_id(contribution_id: ContributionId) -> (project_id: felt) {
}

@storage_var
func contribution_status_(contribution_id: ContributionId) -> (status: felt) {
}

@storage_var
func contribution_contributor_(contribution_id: ContributionId) -> (contributor_id: Uint256) {
}

@storage_var
func contribution_gate_(contribution_id: ContributionId) -> (gate: felt) {
}

@storage_var
func contribution_count_() -> (contribution_count: felt) {
}

@storage_var
func past_contributions_(contributor_id: Uint256) -> (contribution_count: felt) {
}

@storage_var
func github_ids_to_contribution_id(project_id: felt, issue_numer: felt) -> (
    contribution_id: ContributionId
) {
}

//
// Functions
//
namespace contributions {
    func initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(admin: felt) {
        access_control.initialize(admin);
        return ();
    }

    //
    // Write
    //
    func deploy_new_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        project_id: felt, issue_number: felt, gate: felt
    ) -> (contribution: Contribution) {
        alloc_locals;

        const GITHUB_CONTRIBUTION_CLASS_HASH = 0x2c88a0e0e75552a1f256b76b437287dca326b28a1df3cec0be41d1375470cd1;
        let (this) = get_contract_address();
        let (current_salt) = contributions_deploy_salt_.read();

        let (contract_address) = deploy(
            class_hash=GITHUB_CONTRIBUTION_CLASS_HASH,
            contract_address_salt=current_salt,
            constructor_calldata_size=0,
            constructor_calldata=new (),
            deploy_from_zero=FALSE,
        );
        ContributionDeployed.emit(contract_address);

        // TODO: set another default strategy to deploy (a composite one)
        let (local calldata) = alloc();
        assert calldata[0] = project_id;
        assert calldata[1] = issue_number;
        assert calldata[2] = 0x2e19da033a890fe57f423ae30304f60688afd89ff3baeca125bf0b13e19fdc3;  // ClosableStrategyClassHash

        IGithubContribution.initialize(contract_address, calldata_len=3, calldata=calldata);

        contributions_deploy_salt_.write(value=current_salt + 1);
        contribution_project_id.write(ContributionId(contract_address), project_id);

        let contribution = Contribution(
            id=ContributionId(contract_address),
            project_id=project_id,
            status=Status.OPEN,
            gate=gate,
            contributor_id=Uint256(0, 0),
        );
        return (contribution,);
    }

    // DEPRECATED - only used in unit tests to validate legacy way of creating contributions
    // Add a contribution for a given token id
    func new_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        project_id: felt, issue_number: felt, gate: felt
    ) -> (contribution: Contribution) {
        alloc_locals;

        project_access.assert_project_id_is_valid(project_id);
        access_control.only_lead_contributor(project_id);

        with_attr error_message("Contributions: Invalid gate") {
            let gate_sign = sign(gate);
            assert 0 = gate_sign * (1 - gate_sign);
            assert_nn(gate);
        }

        github_access.only_new(project_id, issue_number);

        let (contribution_count) = contribution_count_.read();
        let new_count = contribution_count + 1;
        let id = ContributionId(new_count);

        // Update storage
        contribution_status_.write(id, Status.OPEN);
        contribution_gate_.write(id, gate);
        contribution_project_id.write(id, project_id);
        contribution_count_.write(new_count);
        github_ids_to_contribution_id.write(project_id, issue_number, id);

        ContributionCreated.emit(new_count, project_id, issue_number, gate);

        let contribution = Contribution(id, project_id, Status.OPEN, gate, Uint256(0, 0));

        return (contribution,);
    }

    // Delete a contribution for a given contribution_id
    func delete_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId
    ) {
        let contribution_exists = contribution_access.exists(contribution_id);
        if (contribution_exists == 0) {
            let contract_address = contribution_id.inner;
            IGithubContribution.close(contract_address);
            return ();
        }

        let (project_id) = project_access.find_contribution_project(contribution_id);
        access_control.only_lead_contributor(project_id);
        status_access.only_open(contribution_id);

        // Update storage
        contribution_status_.write(contribution_id, Status.NONE);
        contribution_gate_.write(contribution_id, 0);
        contribution_project_id.write(contribution_id, 0);

        ContributionDeleted.emit(contribution_id.inner);

        return ();
    }

    // Assign a contributor to a contribution
    func assign_contributor_to_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contribution_id: ContributionId, contributor_account_address: felt) {
        let contribution_exists = contribution_access.exists(contribution_id);
        if (contribution_exists == 0) {
            let contract_address = contribution_id.inner;
            IContribution.assign(contract_address, contributor_account_address);
            return ();
        }

        let (project_id) = project_access.find_contribution_project(contribution_id);
        access_control.only_lead_contributor(project_id);

        let contributor_id = Uint256(contributor_account_address, 0);
        internal.assign_contributor_to_contribution(contribution_id, contributor_id);

        // Emit event
        ContributionAssigned.emit(contribution_id.inner, contributor_id);

        return ();
    }

    // Unassign a contributor from a contribution
    func unassign_contributor_from_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contribution_id: ContributionId, contributor_account_address: felt) {
        let contribution_exists = contribution_access.exists(contribution_id);
        if (contribution_exists == 0) {
            let contract_address = contribution_id.inner;
            IContribution.unassign(contract_address, contributor_account_address);
            return ();
        }

        let (project_id) = project_access.find_contribution_project(contribution_id);
        access_control.only_lead_contributor(project_id);

        status_access.only_assigned(contribution_id);

        // Update storage
        contribution_contributor_.write(contribution_id, Uint256(0, 0));
        contribution_status_.write(contribution_id, Status.OPEN);

        // Emit event
        ContributionUnassigned.emit(contribution_id.inner);

        return ();
    }

    // Validate a contribution, marking it as completed
    func validate_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId, contributor_account_address: felt
    ) {
        // Increase contributor contribution_count
        // Must be done before forwarding the call to the new contribution contract
        let contributor_id = Uint256(contributor_account_address, 0);
        let (past_contributions) = past_contributions_.read(contributor_id);
        past_contributions_.write(contributor_id, past_contributions + 1);

        let contribution_exists = contribution_access.exists(contribution_id);
        if (contribution_exists == 0) {
            let contract_address = contribution_id.inner;
            IContribution.validate(contract_address, contributor_account_address);
            return ();
        }

        let (project_id) = project_access.find_contribution_project(contribution_id);
        access_control.only_lead_contributor(project_id);

        status_access.only_assigned(contribution_id);

        // Update storage
        contribution_status_.write(contribution_id, Status.COMPLETED);

        // Emit event
        ContributionValidated.emit(contribution_id.inner);

        return ();
    }

    // Modify a contribution count required
    func modify_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId, gate: felt
    ) {
        let contribution_exists = contribution_access.exists(contribution_id);
        if (contribution_exists == 0) {
            let contract_address = contribution_id.inner;
            IGithubContribution.change_gate(contract_address, gate);
            return ();
        }

        let (project_id) = project_access.find_contribution_project(contribution_id);
        access_control.only_lead_contributor(project_id);

        status_access.only_open(contribution_id);

        // Update storage
        contribution_gate_.write(contribution_id, gate);

        // Emit event
        ContributionGateChanged.emit(contribution_id.inner, gate);

        return ();
    }

    // Claim (self-assign) a contributor to a contribution
    func claim_contribution{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId, contributor_id: Uint256
    ) {
        let contribution_exists = contribution_access.exists(contribution_id);
        if (contribution_exists == 0) {
            let contract_address = contribution_id.inner;
            let contributor_account = internal.get_account_caller_address();
            contribution_contributor_.write(contribution_id, contributor_id);
            IContribution.assign(contract_address, contributor_account);
            return ();
        }

        let (project_id) = project_access.find_contribution_project(contribution_id);
        access_control.only_project_member_or_lead_contributor(project_id);

        internal.assign_contributor_to_contribution(contribution_id, contributor_id);

        // Emit event
        ContributionClaimed.emit(contribution_id.inner, contributor_id);

        return ();
    }

    //
    // Read Only
    //

    // Get the number of past contributions for a given contributor
    func past_contributions_count{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account
    ) -> felt {
        let (count: felt) = past_contributions_.read(Uint256(contributor_account, 0));
        return count;
    }

    func add_lead_contributor_for_project{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(project_id: felt, lead_contributor_account: felt) {
        access_control.grant_lead_contributor_role_for_project(
            project_id, lead_contributor_account
        );
        LeadContributorAdded.emit(project_id, lead_contributor_account);
        return ();
    }

    func remove_lead_contributor_for_project{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(project_id: felt, lead_contributor_account: felt) {
        access_control.revoke_lead_contributor_role_for_project(
            project_id, lead_contributor_account
        );
        LeadContributorRemoved.emit(project_id, lead_contributor_account);
        return ();
    }

    func add_member_for_project{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        project_id: felt, contributor_account: felt
    ) {
        access_control.grant_member_role_for_project(project_id, contributor_account);
        ProjectMemberAdded.emit(project_id, contributor_account);
        return ();
    }

    func remove_member_for_project{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        project_id: felt, contributor_account: felt
    ) {
        access_control.revoke_member_role_for_project(project_id, contributor_account);
        ProjectMemberRemoved.emit(project_id, contributor_account);
        return ();
    }

    func is_lead_contributor{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account
    ) -> (res: felt) {
        let (contribution_contract) = get_caller_address();
        let (project_id) = project_access.find_contribution_project(
            ContributionId(contribution_contract)
        );
        let (is_lead) = access_control.is_lead_contributor(project_id, contributor_account);
        return (is_lead,);
    }

    func is_member{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contributor_account
    ) -> (res: felt) {
        let (contribution_contract) = get_caller_address();
        let (project_id) = project_access.find_contribution_project(
            ContributionId(contribution_contract)
        );
        let (is_member) = access_control.is_project_member(project_id, contributor_account);

        return (is_member,);
    }
}

namespace project_access {
    func assert_project_id_is_valid{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(project_id: felt) {
        with_attr error_message("Contributions: Invalid project ID ({project_id})") {
            assert_nn(project_id);
            assert_not_zero(project_id);
        }
        return ();
    }

    func find_contribution_project{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId
    ) -> (project_id: felt) {
        let (project_id) = contribution_project_id.read(contribution_id);
        with_attr error_message("Contributions: Contribution does not exist") {
            assert_not_zero(project_id);
        }

        return (project_id,);
    }
}

namespace gating {
    func is_contributor_eligible{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        gate: felt, contributor_id: Uint256
    ) -> (result: felt) {
        alloc_locals;
        let (past_contribution_count) = past_contributions_.read(contributor_id);
        let result = is_le(gate, past_contribution_count);
        return (result=result);
    }

    func assert_contributor_is_eligible{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contribution_id: ContributionId, contributor_id: Uint256) {
        let (gate) = contribution_gate_.read(contribution_id);
        let (is_eligible) = is_contributor_eligible(gate, contributor_id);
        with_attr error_message("Contributions: Contributor is not eligible") {
            assert 1 = is_eligible;
        }
        return ();
    }
}

namespace github_access {
    func only_new{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        project_id: felt, issue_number: felt
    ) {
        let (id) = github_ids_to_contribution_id.read(project_id, issue_number);
        let inner = id.inner;
        with_attr error_message("Contributions: Contribution already exist with id {id}") {
            assert 0 = inner;
        }
        return ();
    }
}

namespace status_access {
    func only_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId
    ) {
        alloc_locals;
        let (status) = contribution_status_.read(contribution_id);
        internal.status_is_not_none(status);
        with_attr error_message("Contributions: Contribution is not OPEN") {
            assert Status.OPEN = status;
        }
        return ();
    }

    func only_assigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId
    ) {
        alloc_locals;
        let (status) = contribution_status_.read(contribution_id);
        internal.status_is_not_none(status);
        with_attr error_message("Contributions: Contribution is not ASSIGNED") {
            assert Status.ASSIGNED = status;
        }
        return ();
    }
}

namespace contribution_access {
    func build{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId
    ) -> (contribution: Contribution) {
        let (status) = contribution_status_.read(contribution_id);
        let (gate) = contribution_gate_.read(contribution_id);
        let (contributor) = contribution_contributor_.read(contribution_id);
        let (project_id) = contribution_project_id.read(contribution_id);

        let contribution = Contribution(contribution_id, project_id, status, gate, contributor);
        return (contribution,);
    }

    func is_open{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution: Contribution*
    ) -> (is_open: felt) {
        if (contribution.status == Status.OPEN) {
            return (is_open=1);
        }
        return (is_open=0);
    }

    func exists{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_id: ContributionId
    ) -> felt {
        let (status) = contribution_status_.read(contribution_id);
        if (status == Status.NONE) {
            return 0;
        }
        return 1;
    }
}

namespace internal {
    func status_is_not_none(status: felt) {
        with_attr error_message("Contributions: Contribution does not exist") {
            assert_not_zero(status);
        }
        return ();
    }

    func fetch_contribution_loop{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        contribution_index: felt, contributions: Contribution*
    ) -> (contributions_len: felt) {
        alloc_locals;

        if (contribution_index == 0) {
            return (0,);
        }

        let (local contributions_len) = fetch_contribution_loop(
            contribution_index - 1, contributions
        );

        let contribution_id = ContributionId(contribution_index);
        let (contribution) = contribution_access.build(contribution_id);
        assert contributions[contributions_len] = contribution;

        return (contributions_len=contributions_len + 1);
    }

    func fetch_contribution_assigned_to_loop{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contribution_index: felt, contributions: Contribution*, contributor_id: Uint256) -> (
        contributions_len: felt
    ) {
        alloc_locals;
        if (contribution_index == 0) {
            return (0,);
        }

        let (contributions_len) = fetch_contribution_assigned_to_loop(
            contribution_index - 1, contributions, contributor_id
        );

        let contribution_id = ContributionId(contribution_index);
        let (local contribution) = contribution_access.build(contribution_id);

        let (same_contributor) = uint256_eq(contribution.contributor_id, contributor_id);
        if (same_contributor * (1 - contribution.status + Status.ASSIGNED) == 1) {
            assert contributions[contributions_len] = contribution;
            tempvar contributions_len = contributions_len + 1;
        } else {
            tempvar contributions_len = contributions_len;
        }

        return (contributions_len,);
    }

    func fetch_contribution_eligible_to_loop{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contribution_index: felt, contributions: Contribution*, contributor_id: Uint256) -> (
        contributions_len: felt
    ) {
        alloc_locals;
        if (contribution_index == 0) {
            return (0,);
        }

        let (contributions_len) = fetch_contribution_eligible_to_loop(
            contribution_index - 1, contributions, contributor_id
        );

        let contribution_id = ContributionId(contribution_index);

        let (contribution) = contribution_access.build(contribution_id);
        let (contributor_eligible) = gating.is_contributor_eligible(
            contribution.gate, contributor_id
        );
        if (contributor_eligible == 1) {
            assert contributions[contributions_len] = contribution;
            tempvar contributions_len = contributions_len + 1;
        } else {
            tempvar contributions_len = contributions_len;
        }

        return (contributions_len,);
    }

    // Assign a contributor to a contribution without doing access role check, nor emitting any event
    func assign_contributor_to_contribution{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(contribution_id: ContributionId, contributor_id: Uint256) {
        status_access.only_open(contribution_id);
        gating.assert_contributor_is_eligible(contribution_id, contributor_id);

        // Update storage
        contribution_status_.write(contribution_id, Status.ASSIGNED);
        contribution_contributor_.write(contribution_id, contributor_id);

        return ();
    }

    func get_account_caller_address{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> felt {
        let (tx_info: TxInfo*) = get_tx_info();
        return tx_info.account_contract_address;
    }
}
