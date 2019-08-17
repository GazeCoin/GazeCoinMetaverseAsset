pragma solidity ^0.5.11;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// GazeCoin Metaverse Asset (ERC721 Non-Fungible Token)
//
// Deployed to : {TBA}
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for GazeCoin 2019. The MIT Licence.
// ----------------------------------------------------------------------------

import "zeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "zeppelin-solidity/contracts/drafts/Counters.sol";


// ----------------------------------------------------------------------------
// Attributes Data Structure
// ----------------------------------------------------------------------------
library Attributes {
    struct Value {
        bool exists;
        uint index;
        string value;
    }
    struct Data {
        bool initialised;
        mapping(string => Value) entries;
        string[] index;
    }

    event AttributeAdded(uint256 indexed tokenId, string key, string value, uint totalAfter);
    event AttributeRemoved(uint256 indexed tokenId, string key, uint totalAfter);
    event AttributeUpdated(uint256 indexed tokenId, string key, string value);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function hasKey(Data storage self, string memory key) internal view returns (bool) {
        return self.entries[key].exists;
    }
    function add(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
        require(!self.entries[key].exists);
        self.index.push(key);
        self.entries[key] = Value(true, self.index.length - 1, value);
        emit AttributeAdded(tokenId, key, value, self.index.length);
    }
    function remove(Data storage self, uint256 tokenId, string memory key) internal {
        require(self.entries[key].exists);
        uint removeIndex = self.entries[key].index;
        emit AttributeRemoved(tokenId, key, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        string memory lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[key];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function setValue(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
        Value storage _value = self.entries[key];
        require(_value.exists);
        emit AttributeUpdated(tokenId, key, value);
        _value.value = value;
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}


contract GazeCoinGoobers is ERC721Full {
    using Attributes for Attributes.Data;
    using Attributes for Attributes.Value;
    using Counters for Counters.Counter;

    mapping(uint256 => Attributes.Data) attributesByTokenIds;
    Counters.Counter private _tokenIds;

    constructor() ERC721Full("GazeCoin Goobers", "GOOB") public {
    }

    // Mint and burn
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

    // URI
    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender, "ERC721: set URI of token that is not own");
        _setTokenURI(tokenId, uri);
    }

    // Attributes
    function numberOfAttributes(uint256 tokenId) public view returns (uint) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            return 0;
        } else {
            return attributes.length();
        }
    }
    function getKeys(uint256 tokenId) public view returns (string[] memory) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            string[] memory empty;
            return empty;
        } else {
            return attributes.index;
        }
    }
    function getAttribute(uint256 tokenId, string memory key) public view returns (bool _exists, uint _index, string memory _value) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            return (false, 0, "");
        } else {
            Attributes.Value memory attribute = attributes.entries[key];
            return (attribute.exists, attribute.index, attribute.value);
        }
    }
    function getAttributeByIndex(uint256 tokenId, uint256 _index) public view returns (bool _exists, string memory _key, string memory _value) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (attributes.initialised) {
            if (_index < attributes.index.length) {
                string memory key = attributes.index[_index];
                bytes memory keyInBytes = bytes(key);
                if (keyInBytes.length > 0) {
                    Attributes.Value memory attribute = attributes.entries[key];
                    return (attribute.exists, key, attribute.value);
                }
            }
        }
        return (false, "", "");
    }
    function addAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(ownerOf(tokenId) == msg.sender, "ERC721: add attribute of token that is not own");
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            attributes.init();
        }
        if (attributes.entries[key].exists) {
            attributes.setValue(tokenId, key, value);
        } else {
            attributes.add(tokenId, key, value);
        }
    }
    function removeAttribute(uint256 tokenId, string memory key) public {
        require(ownerOf(tokenId) == msg.sender, "ERC721: remove attribute of token that is not own");
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        attributes.remove(tokenId, key);
    }
    function updateAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(ownerOf(tokenId) == msg.sender, "ERC721: update attribute of token that is not own");
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        require(attributes.entries[key].exists);
        attributes.setValue(tokenId, key, value);
    }
}
