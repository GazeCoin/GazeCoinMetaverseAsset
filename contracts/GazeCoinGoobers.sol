pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// GazeCoin Metaverse Non
//
// Deployed to : {TBA}
//
// Note: Calculations are based on GZE having 18 decimal places
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for GazeCoin 2017. The MIT Licence.
// ----------------------------------------------------------------------------

import "zeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "zeppelin-solidity/contracts/drafts/Counters.sol";

contract GazeCoinGoobers is ERC721Full {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor() ERC721Full("GazeCoin Goobers", "GOOB") public {
    }

    function mint(address to) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
        return newTokenId;
    }

    function mintWithTokenURI(address to, string memory tokenURI) public returns (uint256) {
        _tokenIds.increment();

        uint256 newTokenId = _tokenIds.current();
        _mint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        return newTokenId;
    }

    function burn(uint256 tokenId) public {
        _burn(msg.sender, tokenId);
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(ownerOf(tokenId) == owner, "ERC721: set URI of token that is not own");
        _setTokenURI(tokenId, uri);
    }
}
