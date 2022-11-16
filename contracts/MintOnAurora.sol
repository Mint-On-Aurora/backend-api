/// @author -brownDev-
/// @title Free NFT/Token Minting Service On The Aurora+ Ecosystem
/// @notice Design based on 'NatSpec' and the 'Style Guide' mentioned in the Solidity Documentation.

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @notice Allows children to implement role-based access control mechanisms.
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice A standard interface for contracts that manage multiple token types with storage based token URI management.
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";

/// @notice To keep track of the current token id while creating a new token.
import "@openzeppelin/contracts/utils/Counters.sol";

error MOA_NotTheAdmin();
error MOA_NotAMinter();
error MOA_AlreadyAMinter();

contract MintOnAurora is ERC1155URIStorage, AccessControl {
    /// @dev To assign a new tokenId automatically when a new mint is introduced and increments the tokenId
    /// @dev after the minting operation.
    using Counters for Counters.Counter;
    Counters.Counter private tokenIdTracker;

    /// @notice The MINTER_ADMIN. Also the owner of the contract.
    address public immutable i_ADMIN;

    /// @notice Both single mints and batch mints are allowed to be executed only if the caller
    /// @notice is a Minter (MINTER_ROLE).
    /// @notice Helps restrict access to the minting functions.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Allows the address to change the baseURI and help manage the MINTER_ROLE members.
    bytes32 public constant MINTER_ADMIN = keccak256("MINTER_ADMIN");

    /// @dev Used to create the final URI that is returned in the getURI().
    string private baseURI = "ipfs://";

    // EVENTS INFORMATION ---------
    /// @notice Minting events(TransferSingle and TransferBatch) are emitted  by _mint and _mintBatch internal
    /// @notice functions respectively and are defined in 'ERC-1155.sol'.
    /// @notice Role related events like RoleGranted, RoleAdminChanged, RoleRevoked are emitted by _grantRole,
    /// @notice _setRoleAdmin, _revokeRole internal functions respectively and are defined in 'AccessControl.sol'.

    /// @dev Modifier to restrict adding/removing MINTER_ROLE members along with the baseURI.
    modifier isAdmin() {
        if (!hasRole(MINTER_ADMIN, _msgSender())) revert MOA_NotTheAdmin();
        _;
    }

    /// @dev Modifier to restrict minting of tokens only to the addresses alloted the MINTER_ROLE.
    modifier isMinter() {
        if (!hasRole(MINTER_ROLE, _msgSender())) revert MOA_NotAMinter();
        _;
    }

    /// @dev The minter/admin/owner are EOAs under the platform.
    /// @param _minter The address which will assigned the MINTER_ROLE.
    constructor(address _minter) ERC1155(baseURI) {
        _setRoleAdmin(MINTER_ROLE, MINTER_ADMIN);
        _grantRole(MINTER_ADMIN, _msgSender());
        _grantRole(MINTER_ROLE, _minter);

        i_ADMIN = _msgSender();
    }

    /// @dev This function returns the the URI linked to the provided _tokenId with the help of the baseURI and
    /// @dev the _tokenURIs mapping. If the tokenId doesn't exist in the mapping just yet, 'ipfs://' is returned.
    function tokenURI(uint _tokenId) external view returns (string memory) {
        return uri(_tokenId);
    }

    /// @dev The core function that enables Single Mints. They can either have a supply of 1+ or
    /// @dev just '1' that implies a unique token.
    /// @param _redeemer The address which will receive the token upon success.
    /// @param _claimable Bool value that lets the MINTER_ROLE to transfer tokens on behalf of the _redeemer.
    /// @param _amount The amount of the tokens to be minted. Will have the same URI.
    /// @param _uri The URI to be associated with the new NFTs.
    function singleMints(
        address _redeemer,
        bool _claimable,
        uint _amount,
        string memory _uri
    ) external isMinter {
        require(_redeemer != address(0), "The receiver can't be 0x00");

        uint currentTokenId = tokenIdTracker.current();

        _mint(_redeemer, currentTokenId, _amount, "");
        _setURI(currentTokenId, _uri);

        if (_claimable) _setApprovalForAll(_redeemer, _msgSender(), _claimable);

        tokenIdTracker.increment();
    }

    /// @dev The core function that enables Batch Mints.
    /// @dev The redeemer upon completion of this function is alloted x tokens, where 'x' is the
    /// @dev length of _amounts[]/_uris[].
    /// @notice The tokenId is generated with each new Token.
    /// @param _redeemer The address which will receive the tokens upon success.
    /// @param _claimable Bool value that lets the MINTER_ROLE to transfer tokens on behalf of the _redeemer.
    /// @param _amounts The amount of the tokens to be minted. Will have the same properties.
    /// @param _uris The URIs to be associated with the new NFTs.
    function batchMints(
        address _redeemer,
        bool _claimable,
        uint[] calldata _prices,
        uint[] calldata _amounts,
        string[] calldata _uris
    ) external isMinter {
        require(_redeemer != address(0), "The receiver can't be 0x00");
        require(
            _amounts.length == _uris.length && _uris.length == _prices.length,
            "Parameter arrays length mismatch!"
        );

        uint[] memory _ids = _createIdArray(_amounts.length);

        _mintBatch(_redeemer, _ids, _amounts, "");
        _assignURIBatch(_ids, _uris);

        if (_claimable) _setApprovalForAll(_redeemer, _msgSender(), _claimable);
    }

    /// @dev Allows the MINTER_ADMIN to allot an address the MINTER_ROLE.
    function removeAMinter(address _toRemove) external isAdmin {
        if (!hasRole(MINTER_ROLE, _toRemove)) revert MOA_NotAMinter();
        revokeRole(MINTER_ROLE, _toRemove);
    }

    /// @dev Allows the MINTER_ADMIN to assign an address the MINTER_ROLE.
    function addAMinter(address _toAdd) external isAdmin {
        if (hasRole(MINTER_ROLE, _toAdd)) revert MOA_AlreadyAMinter();
        grantRole(MINTER_ROLE, _toAdd);
    }

    /// @notice Can be called only by the MINTER_ADMIN.
    /// @dev Updates the baseURL that is prefixed with all the respective URIs.
    /// @param _uri The new string that will be assigned to the baseURI state variable.
    function changeBaseURI(string calldata _uri) external isAdmin {
        _setBaseURI(_uri);
        super._setURI(_uri);
    }

    /// @dev Creates a standard method to publish and detect what interfaces a smart contract implements.
    /// @dev We define the interface identifier as the XOR of all function selectors in the interface.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155)
        returns (bool)
    {
        return
            ERC1155.supportsInterface(interfaceId) ||
            AccessControl.supportsInterface(interfaceId);
    }

    /// @dev Returns an _ids[] which will be used in the batchMint operation.
    /// @param length The number of elements in the _ids[].
    function _createIdArray(uint length) private returns (uint[] memory) {
        uint[] memory _ids = new uint[](length);
        for (uint index = 0; index < length; index++) {
            _ids[index] = tokenIdTracker.current();
            tokenIdTracker.increment();
        }
        return _ids;
    }

    /// @dev Used in the batchMint function. Uses _setURI internally to set the URIs to respective
    /// @dev tokenIds and emit events associated with the minting of tokens and mapping the URI.
    /// @param _ids An array of tokenIds.
    /// @param _uris An array of URIs to be mapped to the respective tokenIds.
    function _assignURIBatch(uint[] memory _ids, string[] calldata _uris)
        private
    {
        uint length = _ids.length;
        for (uint index = 0; index < length; index++) {
            uint _tokenId = _ids[index];
            _setURI(_tokenId, _uris[index]);
        }
    }
}