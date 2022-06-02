%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from onlydust.deathnote.interfaces.badge import Badge

#
# Tests
#
@view
func test_badge_e2e{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    const OWNER = 42
    local contract_address : felt
    %{
        ids.contract_address = deploy_contract("./contracts/onlydust/deathnote/core/badge/badge.cairo", [ids.OWNER]).contract_address 
        stop_prank = start_prank(ids.OWNER, target_contract_address=ids.contract_address)
    %}

    const CONTRIBUTOR = 23
    let (tokenId) = Badge.mint(contract_address, CONTRIBUTOR)

    %{ stop_prank() %}

    let (name) = Badge.name(contract_address)
    assert 'Death Note Badge' = name

    let (symbol) = Badge.symbol(contract_address)
    assert 'DNB' = symbol

    let (owner) = Badge.ownerOf(contract_address, tokenId)
    assert CONTRIBUTOR = owner

    return ()
end
