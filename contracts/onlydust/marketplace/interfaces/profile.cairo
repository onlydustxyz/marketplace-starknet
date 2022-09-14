%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IProfile {
    func name() -> (name: felt) {
    }

    func symbol() -> (symbol: felt) {
    }

    func mint(to: felt) -> (tokenId: Uint256) {
    }

    func ownerOf(tokenId: Uint256) -> (owner: felt) {
    }

    func grant_admin_role(address: felt) {
    }

    func revoke_admin_role(address: felt) {
    }

    func grant_minter_role(address: felt) {
    }

    func revoke_minter_role(address: felt) {
    }
}
