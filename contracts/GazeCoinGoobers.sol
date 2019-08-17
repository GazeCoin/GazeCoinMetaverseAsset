pragma solidity ^0.5.11;
// For getKeys(...) pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// GazeCoin Metaverse Asset (ERC721 Non-Fungible Token)
//
// Deployed to : v1 0x2667E5192Bac646A165b7E4f717A7F1c0418CC27 on Ropsten
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for GazeCoin 2019. The MIT Licence.
// ----------------------------------------------------------------------------

import "zeppelin-solidity/contracts/token/ERC721/ERC721Enumerable.sol";
import "zeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "zeppelin-solidity/contracts/token/ERC721/IERC721Metadata.sol";
import "zeppelin-solidity/contracts/introspection/ERC165.sol";
import "zeppelin-solidity/contracts/drafts/Counters.sol";


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    bool private initialised;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function initOwned(address _owner) internal {
        require(!initialised);
        owner = _owner;
        initialised = true;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


// ----------------------------------------------------------------------------
// Metadata
// ----------------------------------------------------------------------------
contract MyERC721Metadata is ERC165, ERC721, IERC721Metadata, Owned {
    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    string public baseURI = "http://multiverse.gazecoin.io/api/asset/";

    /**
     * @dev Constructor function
     */
    constructor (string memory name, string memory symbol) public {
        initOwned(msg.sender);

        _name = name;
        _symbol = symbol;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

    function uintToBytes(uint256 num) internal pure returns (bytes memory b) {
        if (num == 0) {
            b = new bytes(1);
            b[0] = byte(uint8(48));
        } else {
            uint256 j = num;
            uint256 length;
            while (j != 0) {
                length++;
                j /= 10;
            }
            b = new bytes(length);
            uint k = length - 1;
            while (num != 0) {
                b[k--] = byte(uint8(48 + num % 10));
                num /= 10;
            }
        }
    }

    function setBaseURI(string memory uri) public onlyOwner {
        baseURI = uri;
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory url = _tokenURIs[tokenId];
        bytes memory urlAsBytes = bytes(url);
        if (urlAsBytes.length == 0) {
            bytes memory baseURIAsBytes = bytes(baseURI);
            bytes memory tokenIdAsBytes = uintToBytes(tokenId);
            bytes memory b = new bytes(baseURIAsBytes.length + tokenIdAsBytes.length);
            uint256 i;
            uint256 j;
            for (i = 0; i < baseURIAsBytes.length; i++) {
                b[j++] = baseURIAsBytes[i];
            }
            for (i = 0; i < tokenIdAsBytes.length; i++) {
                b[j++] = tokenIdAsBytes[i];
            }
            return string(b);
        } else {
            return _tokenURIs[tokenId];
        }
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

    function setTokenURI(uint256 tokenId, string memory uri) public {
        require(ownerOf(tokenId) == msg.sender, "ERC721Metadata: set URI of token that is not own");
        _setTokenURI(tokenId, uri);
    }

    /**
     * @dev Internal function to burn a specific token.
     * Reverts if the token does not exist.
     * Deprecated, use _burn(uint256) instead.
     * @param owner owner of the token to burn
     * @param tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}


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


contract GazeCoinGoobers is ERC721Enumerable, MyERC721Metadata {
    using Attributes for Attributes.Data;
    using Attributes for Attributes.Value;
    using Counters for Counters.Counter;

    mapping(uint256 => Attributes.Data) private attributesByTokenIds;
    Counters.Counter private _tokenIds;

    // Duplicated from Attributes for NFT contract ABI to contain events
    event AttributeAdded(uint256 indexed tokenId, string key, string value, uint totalAfter);
    event AttributeRemoved(uint256 indexed tokenId, string key, uint totalAfter);
    event AttributeUpdated(uint256 indexed tokenId, string key, string value);

    constructor() MyERC721Metadata("GazeCoin Goobers v1", "GOOBv1") public {
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

    // Attributes
    function numberOfAttributes(uint256 tokenId) public view returns (uint) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            return 0;
        } else {
            return attributes.length();
        }
    }
    // NOTE - Solidity returns an incorrect value
    // function getKeys(uint256 tokenId) public view returns (string[] memory) {
    //     Attributes.Data storage attributes = attributesByTokenIds[tokenId];
    //     if (!attributes.initialised) {
    //         string[] memory empty;
    //         return empty;
    //     } else {
    //         return attributes.index;
    //     }
    // }
    // function getKey(uint256 tokenId, uint _index) public view returns (string memory) {
    //     Attributes.Data storage attributes = attributesByTokenIds[tokenId];
    //     if (attributes.initialised) {
    //         if (_index < attributes.index.length) {
    //             return attributes.index[_index];
    //         }
    //     }
    //     return "";
    // }
    // function getValue(uint256 tokenId, string memory key) public view returns (bool _exists, uint _index, string memory _value) {
    //     Attributes.Data storage attributes = attributesByTokenIds[tokenId];
    //     if (!attributes.initialised) {
    //         return (false, 0, "");
    //     } else {
    //         Attributes.Value memory attribute = attributes.entries[key];
    //         return (attribute.exists, attribute.index, attribute.value);
    //     }
    // }
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
        require(ownerOf(tokenId) == msg.sender, "GazeCoinGoobers: add attribute of token that is not own");
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
        require(ownerOf(tokenId) == msg.sender, "GazeCoinGoobers: remove attribute of token that is not own");
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        attributes.remove(tokenId, key);
    }
    function updateAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(ownerOf(tokenId) == msg.sender, "GazeCoinGoobers: update attribute of token that is not own");
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        require(attributes.entries[key].exists);
        attributes.setValue(tokenId, key, value);
    }
}
