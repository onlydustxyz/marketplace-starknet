%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from openzeppelin.token.erc721.library import (
    ERC721_initializer,
    ERC721_name,
    ERC721_symbol,
    ERC721_mint,
    ERC721_ownerOf,
)

from openzeppelin.access.ownable import Ownable

from openzeppelin.security.safemath import SafeUint256

#
# STORAGE
#
@storage_var
func totalSupply() -> (totalSupply : Uint256):
end

namespace badge:
    # Initialize the badge name and symbol
    func initialize{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt
    ):
        ERC721_initializer('Death Note Badge', 'DNB')
        Ownable.initializer(owner)
        return ()
    end

    # Get the badge name
    func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
        return ERC721_name()
    end

    # Get the badge symbol
    func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        symbol : felt
    ):
        return ERC721_symbol()
    end

    # Mint a new token
    func mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(to : felt) -> (
        tokenId : Uint256
    ):
        alloc_locals

        Ownable.assert_only_owner()

        let (local tokenId : Uint256) = totalSupply.read()
        ERC721_mint(to, tokenId)

        let (new_supply) = SafeUint256.add(tokenId, Uint256(1, 0))
        totalSupply.write(new_supply)

        return (tokenId)
    end

    # Get the owner of a tokenId
    func ownerOf{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        tokenId : Uint256
    ) -> (owner : felt):
        return ERC721_ownerOf(tokenId)
    end
end
