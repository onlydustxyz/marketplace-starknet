%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace Badge:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func mint(to : felt) -> (tokenId : Uint256):
    end

    func ownerOf(tokenId : Uint256) -> (owner : felt):
    end
end
