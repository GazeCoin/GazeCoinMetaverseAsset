pragma solidity ^0.5.11;

// For array of strings in the parameter. Not working correctly. pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// GazeCoin Metaverse Asset (ERC721 Non-Fungible Token)
//
// Deployed to : v11 0xba2F79db60dAFc20Ca38b9CFa419a0Afc69842f1 on Ropsten
//
// TODO:
//   * Create a list of allowable attributes, optional or mandatory
//     with a defined list or unlimited with certain attributes updatable
//     by the token contract owner
//   * Allow token owner to permission secondary accounts
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

    string public baseURI = "https://goblok.world/api/token/";

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

    // BK NOTE - Disable as not required currently
    // function setTokenURI(uint256 tokenId, string memory uri) public {
    //     require(ownerOf(tokenId) == msg.sender, "ERC721Metadata: set URI of token that is not own");
    //     _setTokenURI(tokenId, uri);
    // }

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
        uint timestamp;
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
        return self.entries[key].timestamp > 0;
    }
    function add(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
        require(self.entries[key].timestamp == 0);
        self.index.push(key);
        self.entries[key] = Value(block.timestamp, self.index.length - 1, value);
        emit AttributeAdded(tokenId, key, value, self.index.length);
    }
    function remove(Data storage self, uint256 tokenId, string memory key) internal {
        require(self.entries[key].timestamp > 0);
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
    function removeAll(Data storage self, uint256 tokenId) internal {
        if (self.initialised) {
            while (self.index.length > 0) {
                uint lastIndex = self.index.length - 1;
                string memory lastIndexKey = self.index[lastIndex];
                emit AttributeRemoved(tokenId, lastIndexKey, lastIndex);
                delete self.entries[lastIndexKey];
                self.index.length--;
            }
        }
    }
    function setValue(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
        Value storage _value = self.entries[key];
        require(_value.timestamp > 0);
        _value.timestamp = block.timestamp;
        emit AttributeUpdated(tokenId, key, value);
        _value.value = value;
    }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}


// ----------------------------------------------------------------------------
// Secondary Accounts Data Structure
// ----------------------------------------------------------------------------
library Accounts {
    struct Account {
        uint timestamp;
        uint index;
        address account;
    }
    struct Data {
        bool initialised;
        mapping(address => Account) entries;
        address[] index;
    }

    event AccountAdded(address owner, address account, uint totalAfter);
    event AccountRemoved(address owner, address account, uint totalAfter);
    // event AccountUpdated(uint256 indexed tokenId, address owner, address account);

    function init(Data storage self) internal {
        require(!self.initialised);
        self.initialised = true;
    }
    function hasKey(Data storage self, address account) internal view returns (bool) {
        return self.entries[account].timestamp > 0;
    }
    function add(Data storage self, address owner, address account) internal {
        require(self.entries[account].timestamp == 0);
        self.index.push(account);
        self.entries[account] = Account(block.timestamp, self.index.length - 1, account);
        emit AccountAdded(owner, account, self.index.length);
    }
    function remove(Data storage self, address owner, address account) internal {
        require(self.entries[account].timestamp > 0);
        uint removeIndex = self.entries[account].index;
        emit AccountRemoved(owner, account, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexKey = self.index[lastIndex];
        self.index[removeIndex] = lastIndexKey;
        self.entries[lastIndexKey].index = removeIndex;
        delete self.entries[account];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function removeAll(Data storage self, address owner) internal {
        if (self.initialised) {
            while (self.index.length > 0) {
                uint lastIndex = self.index.length - 1;
                address lastIndexKey = self.index[lastIndex];
                emit AccountRemoved(owner, lastIndexKey, lastIndex);
                delete self.entries[lastIndexKey];
                self.index.length--;
            }
        }
    }
    // function setValue(Data storage self, uint256 tokenId, string memory key, string memory value) internal {
    //     Value storage _value = self.entries[key];
    //     require(_value.timestamp > 0);
    //     _value.timestamp = block.timestamp;
    //     emit AttributeUpdated(tokenId, key, value);
    //     _value.value = value;
    // }
    function length(Data storage self) internal view returns (uint) {
        return self.index.length;
    }
}


contract GazeCoinGoobers is ERC721Enumerable, MyERC721Metadata {
    using Attributes for Attributes.Data;
    using Attributes for Attributes.Value;
    using Counters for Counters.Counter;
    using Accounts for Accounts.Data;
    using Accounts for Accounts.Account;

    string public constant TYPE_KEY = "type";
    string public constant SUBTYPE_KEY = "subtype";
    string public constant NAME_KEY = "name";
    string public constant DESCRIPTION_KEY = "description";
    string public constant TAGS_KEY = "tags";

    mapping(uint256 => string) baseAttributesDataByTokenIds;
    mapping(uint256 => uint256) baseAttributesDataTimestampByTokenIds;
    mapping(uint256 => Attributes.Data) private attributesByTokenIds;
    Counters.Counter private _tokenIds;
    mapping(address => Accounts.Data) private secondaryAccounts;

    event BaseAttributesDataUpdated(uint256 indexed tokenId, string baseAttributesData);

    // Duplicated from Attributes for NFT contract ABI to contain events
    event AttributeAdded(uint256 indexed tokenId, string key, string value, uint totalAfter);
    event AttributeRemoved(uint256 indexed tokenId, string key, uint totalAfter);
    event AttributeUpdated(uint256 indexed tokenId, string key, string value);

    event AccountAdded(address owner, address account, uint totalAfter);
    event AccountRemoved(address owner, address account, uint totalAfter);
    // event AccountUpdated(uint256 indexed tokenId, address owner, address account);

    constructor() MyERC721Metadata("GazeCoin Goobers v11", "GOOBv11") public {
    }

    // Mint and burn

    /**
     * @dev Mint token
     *
     * @param _to address of token owner
     * @param _type Type of token, mandatory
     * @param _subtype Subtype of token, optional
     * @param _name Name of token, optional
     * @param _description Description of token, optional
     * @param _tags Tags of token, optional
     */
    function mint(address _to, string memory _type, string memory _subtype, string memory _name, string memory _description, string memory _tags) public returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(_to, newTokenId);

        bytes memory typeInBytes = bytes(_type);
        require(typeInBytes.length > 0);

        Attributes.Data storage attributes = attributesByTokenIds[newTokenId];
        attributes.init();
        attributes.add(newTokenId, TYPE_KEY, _type);

        bytes memory subtypeInBytes = bytes(_subtype);
        if (subtypeInBytes.length > 0) {
            attributes.add(newTokenId, SUBTYPE_KEY, _subtype);
        }

        bytes memory nameInBytes = bytes(_name);
        if (nameInBytes.length > 0) {
            attributes.add(newTokenId, NAME_KEY, _name);
        }

        bytes memory descriptionInBytes = bytes(_description);
        if (descriptionInBytes.length > 0) {
            attributes.add(newTokenId, DESCRIPTION_KEY, _description);
        }

        bytes memory tagsInBytes = bytes(_tags);
        if (tagsInBytes.length > 0) {
            attributes.add(newTokenId, TAGS_KEY, _tags);
        }

        return newTokenId;
    }
    // BELOW DOES NOT WORK CORRECTLY
    // function mintWithAttributes(address to, string[] memory keys, string[] memory values) public returns (uint256) {
    //     require(keys.length == values.length);
    //     _tokenIds.increment();
    //     uint256 newTokenId = _tokenIds.current();
    //     _mint(to, newTokenId);
    //     for (uint256 i = 0; i < keys.length; i++) {
    //         addAttribute(newTokenId, keys[i], values[i]);
    //     }
    //     return newTokenId;
    // }
    // function mintWithTokenURI(address to, string memory tokenURI) public returns (uint256) {
    //     _tokenIds.increment();
    //
    //     uint256 newTokenId = _tokenIds.current();
    //     _mint(to, newTokenId);
    //     _setTokenURI(newTokenId, tokenURI);
    //
    //     return newTokenId;
    // }
    function burn(uint256 tokenId) public {
        // TODO - attributes.removeAll(...)
        // TODO - GAS COST IF THERE ARE LOTS OF ATTRIBUTES
        _burn(msg.sender, tokenId);
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (attributes.initialised) {
            attributes.removeAll(tokenId);
            delete attributesByTokenIds[tokenId];
        }
        delete baseAttributesDataByTokenIds[tokenId];
        delete baseAttributesDataTimestampByTokenIds[tokenId];
    }

    // baseAttributesData
    function getBaseAttributesData(uint256 tokenId) public view returns (string memory _baseAttributesData, uint timestamp) {
        return (baseAttributesDataByTokenIds[tokenId], baseAttributesDataTimestampByTokenIds[tokenId]);
    }
    function setBaseAttributesData(uint256 tokenId, string memory baseAttributesData) public {
        require(isOwnerOf(tokenId, msg.sender), "GazeCoinGoobers: set base attributes data of token that is not own");
        baseAttributesDataByTokenIds[tokenId] = baseAttributesData;
        baseAttributesDataTimestampByTokenIds[tokenId] = block.timestamp;
        emit BaseAttributesDataUpdated(tokenId, baseAttributesData);
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
    function getAttributeByIndex(uint256 tokenId, uint256 _index) public view returns (string memory _key, string memory _value, uint timestamp) {
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (attributes.initialised) {
            if (_index < attributes.index.length) {
                string memory key = attributes.index[_index];
                bytes memory keyInBytes = bytes(key);
                if (keyInBytes.length > 0) {
                    Attributes.Value memory attribute = attributes.entries[key];
                    return (key, attribute.value, attribute.timestamp);
                }
            }
        }
        return ("", "", 0);
    }
    function addAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(isOwnerOf(tokenId, msg.sender), "GazeCoinGoobers: add attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            attributes.init();
        }
        require(attributes.entries[key].timestamp == 0);
        attributes.add(tokenId, key, value);
    }
    function setAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(isOwnerOf(tokenId, msg.sender), "GazeCoinGoobers: set attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        if (!attributes.initialised) {
            attributes.init();
        }
        if (attributes.entries[key].timestamp > 0) {
            attributes.setValue(tokenId, key, value);
        } else {
            attributes.add(tokenId, key, value);
        }
    }
    function removeAttribute(uint256 tokenId, string memory key) public {
        require(isOwnerOf(tokenId, msg.sender), "GazeCoinGoobers: remove attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        attributes.remove(tokenId, key);
    }
    function updateAttribute(uint256 tokenId, string memory key, string memory value) public {
        require(isOwnerOf(tokenId, msg.sender), "GazeCoinGoobers: update attribute of token that is not own");
        require(keccak256(abi.encodePacked(key)) != keccak256(abi.encodePacked(TYPE_KEY)));
        Attributes.Data storage attributes = attributesByTokenIds[tokenId];
        require(attributes.initialised);
        require(attributes.entries[key].timestamp > 0);
        attributes.setValue(tokenId, key, value);
    }

    function isOwnerOf(uint tokenId, address account) public view returns (bool) {
        address owner = ownerOf(tokenId);
        if (owner == account) {
            return true;
        } else {
            Accounts.Data storage accounts = secondaryAccounts[owner];
            if (accounts.initialised) {
                if (accounts.hasKey(account)) {
                    return true;
                }
            }
        }
        return false;
    }
    function addSecondaryAccount(address account) public {
        require(account != address(0), "GazeCoinGoobers: cannot add null secondary account");
        Accounts.Data storage accounts = secondaryAccounts[msg.sender];
        if (!accounts.initialised) {
            accounts.init();
        }
        require(accounts.entries[account].timestamp == 0);
        accounts.add(msg.sender, account);
    }
    function removeSecondaryAccount(address account) public {
        require(account != address(0), "GazeCoinGoobers: cannot remove null secondary account");
        Accounts.Data storage accounts = secondaryAccounts[msg.sender];
        require(accounts.initialised);
        accounts.remove(msg.sender, account);
    }
}
