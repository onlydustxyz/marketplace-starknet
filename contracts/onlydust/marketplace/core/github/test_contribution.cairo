%lang starknet

from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_contract_address, get_caller_address

from onlydust.marketplace.core.github.contribution import (
    initialize,
    assign,
    unassign,
    validate,
    modify_gate,
    delete,
)

const ADMIN = 'admin';
const REPO_ID = 'MyProject';
const LEAD_CONTRIBUTOR_ACCOUNT = 'lead';
const PROJECT_MEMBER_ACCOUNT = 'member';
const ORACLE = 1000;
const PROJECT_CONTRACT = 1001;

@view
func test_contribution_initialization_event{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    initialize(
        contributor_oracle=ORACLE,
        project_contract=PROJECT_CONTRACT,
        repo_id=REPO_ID,
        issue_number=12,
        gate=2,
    );

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionCreated", "data": {"contribution_id": ids.contract_address, "project_id": ids.REPO_ID,  "issue_number": 12, "gate": 2}},
           )
    %}
    return ();
}

@view
func test_contribution_can_be_initialized_only_once{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;

    initialize(
        contributor_oracle=ORACLE,
        project_contract=PROJECT_CONTRACT,
        repo_id=REPO_ID,
        issue_number=12,
        gate=2,
    );

    %{ expect_revert() %}

    initialize(
        contributor_oracle=ORACLE,
        project_contract=PROJECT_CONTRACT,
        repo_id=REPO_ID,
        issue_number=12,
        gate=2,
    );
    return ();
}

@view
func test_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contract_address, "contributor_id": {"low": ids.contributor_account, "high": 0}}},
           )
    %}
    return ();
}

@view
func test_claim{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project_1 = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        stop_mock_project_2 = mock_call(ids.PROJECT_CONTRACT, "is_member", [1])
        stop_prank = start_prank(ids.contributor_account)
    %}
    assign(contributor_account);
    %{
        stop_prank()
        stop_mock_project_1()
        stop_mock_project_2()
        stop_mock_oracle()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionClaimed", "data": {"contribution_id": ids.contract_address, "contributor_id": {"low": ids.contributor_account, "high": 0}}},
           )
    %}
    return ();
}

@view
func test_cannot_assign_when_not_elligible{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [0])
        stop_mock_project_1 = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        expect_revert(error_message="Contribution: Contributor is not eligible")
    %}
    assign(contributor_account);
    %{
        stop_mock_project_1()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_cannot_claim_for_someone_else{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 43;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project_1 = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        stop_mock_project_2 = mock_call(ids.PROJECT_CONTRACT, "is_member", [1])
        stop_prank = start_prank(666)
        expect_revert(error_message="Contribution: LEAD_CONTRIBUTOR or PROJECT_MEMBER role required")
    %}
    assign(contributor_account);
    %{
        stop_prank() 
        stop_mock_project_1()
        stop_mock_project_2()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_cannot_assign_when_not_lead_or_member{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 43;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project_1 = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        stop_mock_project_2 = mock_call(ids.PROJECT_CONTRACT, "is_member", [0])
        stop_prank = start_prank(666)
        expect_revert(error_message="Contribution: LEAD_CONTRIBUTOR or PROJECT_MEMBER role required")
    %}
    assign(contributor_account);
    %{
        stop_prank() 
        stop_mock_project_1()
        stop_mock_project_2()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_cannot_assign_when_already_assigned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    %{ expect_revert(error_message="Contribution: Contribution is not OPEN") %}
    assign(1111);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}

    return ();
}

@view
func test_cannot_assign_when_deleted{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    delete();
    %{ expect_revert(error_message="Contribution: Contribution is not OPEN") %}
    assign(1111);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}

    return ();
}

@view
func test_reassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();

    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    unassign(contributor_account);
    assign(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contract_address, "contributor_id": {"low": ids.contributor_account, "high": 0}}},
               {"name": "ContributionUnassigned", "data": {"contribution_id": ids.contract_address}},
               {"name": "ContributionAssigned", "data": {"contribution_id": ids.contract_address, "contributor_id": {"low": ids.contributor_account, "high": 0}}},
           )
    %}
    return ();
}

@view
func test_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();
    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    unassign(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionUnassigned", "data": {"contribution_id": ids.contract_address}},
           )
    %}
    return ();
}

@view
func test_cannot_unassign_when_not_lead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();
    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    %{
        stop_mock_project()
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        expect_revert(error_message="Contribution: LEAD_CONTRIBUTOR role required")
    %}
    unassign(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_cannot_unassign_when_not_assigned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();
    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contribution: Contribution is not ASSIGNED")
    %}
    unassign(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();
    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    validate(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionValidated", "data": {"contribution_id": ids.contract_address}},
           )
    %}
    return ();
}

@view
func test_cannot_validate_when_not_lead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();
    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    assign(contributor_account);
    %{
        stop_mock_project()
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        expect_revert(error_message="Contribution: LEAD_CONTRIBUTOR role required")
    %}
    validate(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_cannot_validate_when_not_assigned{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();
    let contributor_account = 42;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contribution: Contribution is not ASSIGNED")
    %}
    validate(contributor_account);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_modify_gate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();
    let gate = 8;

    %{
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    modify_gate(gate);
    %{
        stop_prank()
        stop_mock_project()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionGateChanged", "data": {"contribution_id": ids.contract_address, "gate": ids.gate}},
           )
    %}
    return ();
}

@view
func test_cannot_modify_gate_when_not_lead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();
    let gate = 8;

    %{
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contribution: LEAD_CONTRIBUTOR role required")
    %}
    modify_gate(gate);
    %{
        stop_prank()
        stop_mock_project()
    %}
    return ();
}

@view
func test_cannot_modify_gate_when_not_open{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();
    let gate = 8;

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contribution: Contribution is not OPEN")
    %}
    assign(42);
    modify_gate(gate);
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}
    return ();
}

@view
func test_delete{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;
    fixture.init();

    %{
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
    %}
    delete();
    %{
        stop_prank()
        stop_mock_project()
    %}

    let (contract_address) = get_contract_address();
    %{
        expect_events(
               {"name": "ContributionDeleted", "data": {"contribution_id": ids.contract_address}},
           )
    %}
    return ();
}

@view
func test_cannot_delete_when_not_lead{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    %{
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [0])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contribution: LEAD_CONTRIBUTOR role required")
    %}
    delete();
    %{
        stop_prank()
        stop_mock_project()
    %}
    return ();
}

@view
func test_cannot_delete_when_not_open{
    syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
}() {
    alloc_locals;
    fixture.init();

    %{
        stop_mock_oracle = mock_call(ids.ORACLE, "past_contribution_count", [3])
        stop_mock_project = mock_call(ids.PROJECT_CONTRACT, "is_lead_contributor", [1])
        stop_prank = start_prank(ids.LEAD_CONTRIBUTOR_ACCOUNT)
        expect_revert(error_message="Contribution: Contribution is not OPEN")
    %}
    assign(42);
    delete();
    %{
        stop_prank()
        stop_mock_project()
        stop_mock_oracle()
    %}
    return ();
}

namespace fixture {
    func init{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
        initialize(
            contributor_oracle=ORACLE,
            project_contract=PROJECT_CONTRACT,
            repo_id=REPO_ID,
            issue_number=12,
            gate=2,
        );

        return ();
    }
}
