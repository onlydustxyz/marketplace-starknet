%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_contract_address
from onlydust.marketplace.interfaces.assignment_strategy import IAssignmentStrategy

//
// CONSTANTS
//
const CONTRIBUTOR_ADDRESS = 0x069642afc7c6669888f3e8e6c935662b126b2a0ac6c12ca754861d54b4c17556;

//
// INTERFACES
//
@contract_interface
namespace IComposite {
    func initialize(strategies_len, strategies: felt*) {
    }

    func strategies() -> (strategies_len: felt, strategies: felt*) {
    }
}

@contract_interface
namespace ITestStrategy {
    func request_revert() {
    }
}

//
// TESTS
//
func register_selector(function_name, selector) {
    %{ context.selectors[ids.function_name] = ids.selector %}
    return ();
}

@view
func __setup__{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    %{
        context.composite_strategy_hash = declare("./contracts/onlydust/marketplace/core/assignment_strategies/composite.cairo", config={"wait_for_acceptance": True}).class_hash 
        context.test_strategy_hash = declare("./contracts/onlydust/marketplace/test/libraries/assignment_strategy_mock.cairo", config={"wait_for_acceptance": True}).class_hash
        context.selectors = {}
    %}

    register_selector(
        'assert_can_assign', 0xafebfa3bc187991e56ad073c19677f894a3a5541d8b8151af100e49077f937
    );
    register_selector(
        'on_assigned', 0xf897b8b0d9c032035dd00f05036ece8d0323783ada50f77ac038b5ee28a4f7
    );
    register_selector(
        'assert_can_unassign', 0x24d59f9e6d82d630ed029dc7ad5594e04122af91ac85426ec2c05cfec580997
    );
    register_selector(
        'assert_can_validate', 0x335791ca04a8d33572330929a1f5d0ed5ccb04474422093c6ca6cb510ad1bc6
    );

    return ();
}

@view
func test_initialize{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let (local strategies) = alloc();
    assert strategies[0] = 0x1111;
    assert strategies[1] = 0x2222;
    assert strategies[2] = 0x3333;

    let composite_strategy_hash = Composite.declared();
    with composite_strategy_hash {
        Composite.initialize(3, strategies);

        let (strategies_len, strategies) = Composite.strategies();
        assert 3 = strategies_len;
        assert 0x1111 = strategies[0];
        assert 0x2222 = strategies[1];
        assert 0x3333 = strategies[2];
    }

    return ();
}

@view
func test_cannot_initialize_twice{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) {
    %{ expect_revert(error_message="Initializable: contract already initialized") %}
    let composite_strategy_hash = Composite.declared();
    with composite_strategy_hash {
        Composite.initialize(0, new ());
        Composite.initialize(0, new ());
    }

    return ();
}

@view
func test_can_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_assert_can_assign(
        composite_strategy_hash, CONTRIBUTOR_ADDRESS
    );

    let test_strategy_hash = TestStrategy.declared();
    with test_strategy_hash {
        let count = TestStrategy.get_function_call_count('assert_can_assign');
        assert 3 = count;
    }

    return ();
}

@view
func test_cannot_assign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    let test_strategy_hash = TestStrategy.declared();
    with test_strategy_hash {
        TestStrategy.request_revert();
    }

    %{ expect_revert() %}
    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.assert_can_assign(composite_strategy_hash, CONTRIBUTOR_ADDRESS);

    return ();
}

@view
func test_on_assigned{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_on_assigned(composite_strategy_hash, CONTRIBUTOR_ADDRESS);

    let test_strategy_hash = TestStrategy.declared();
    with test_strategy_hash {
        let count = TestStrategy.get_function_call_count('on_assigned');
        assert 3 = count;
    }

    return ();
}

@view
func test_can_unassign{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_assert_can_unassign(
        composite_strategy_hash, CONTRIBUTOR_ADDRESS
    );

    let test_strategy_hash = TestStrategy.declared();
    with test_strategy_hash {
        let count = TestStrategy.get_function_call_count('assert_can_unassign');
        assert 3 = count;
    }

    return ();
}

@view
func test_can_validate{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() {
    alloc_locals;

    let composite_strategy_hash = Composite.default();
    IAssignmentStrategy.library_call_assert_can_validate(
        composite_strategy_hash, CONTRIBUTOR_ADDRESS
    );

    let test_strategy_hash = TestStrategy.declared();
    with test_strategy_hash {
        let count = TestStrategy.get_function_call_count('assert_can_validate');
        assert 3 = count;
    }

    return ();
}

//
// Composite functions
//
namespace Composite {
    func declared{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        tempvar composite_strategy_hash;
        %{ ids.composite_strategy_hash = context.composite_strategy_hash %}
        return composite_strategy_hash;
    }

    func initialize{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, composite_strategy_hash
    }(strategies_len, strategies: felt*) {
        IComposite.library_call_initialize(composite_strategy_hash, strategies_len, strategies);
        return ();
    }

    func strategies{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, composite_strategy_hash
    }() -> (strategies_len: felt, strategies: felt*) {
        let (strategies_len, strategies: felt*) = IComposite.library_call_strategies(
            composite_strategy_hash
        );
        return (strategies_len, strategies);
    }

    func default{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        alloc_locals;

        let test_strategy_hash = TestStrategy.declared();
        let (local strategies) = alloc();
        assert strategies[0] = test_strategy_hash;
        assert strategies[1] = test_strategy_hash;
        assert strategies[2] = test_strategy_hash;

        let composite_strategy_hash = declared();
        with composite_strategy_hash {
            initialize(3, strategies);
        }

        return composite_strategy_hash;
    }
}

//
// TestStratgegy functions
//
namespace TestStrategy {
    func declared{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> felt {
        tempvar test_strategy_hash;
        %{ ids.test_strategy_hash = context.test_strategy_hash %}
        return test_strategy_hash;
    }

    func request_revert{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, test_strategy_hash
    }() {
        ITestStrategy.library_call_request_revert(test_strategy_hash);
        return ();
    }

    func get_function_call_count{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr, test_strategy_hash
    }(function_name) -> felt {
        alloc_locals;
        tempvar function_call_count;
        let (local contract_address) = get_contract_address();
        %{
            selector = context.selectors[ids.function_name]
            storage = load(ids.contract_address, "assignment_strategy__test__function_calls", "felt", key=[selector])
            ids.function_call_count = storage[0]
        %}
        return function_call_count;
    }
}
