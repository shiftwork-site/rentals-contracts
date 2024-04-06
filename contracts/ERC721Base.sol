// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import {ERC721A} from "./ERC721A.sol";

import "./ContractMetadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./BatchMintMetadata.sol";
import "../lib/TWStrings.sol";

/**
 *  The `ERC721Base` smart contract implements the ERC721 NFT standard, along with the ERC721A optimization to the standard.
 *  It includes the following additions to standard ERC721 logic:
 *
 *      - Ability to mint NFTs via the provided `mint` function.
 *
 *      - Contract metadata for royalty support on platforms such as OpenSea that use
 *        off-chain information to distribute roaylties.
 *
 *      - Ownership of the contract, with the ability to restrict certain functions to
 *        only be called by the contract's owner.
 *
 *      - Multicall capability to perform multiple actions atomically
 *
 *      - EIP 2981 compliance for royalty support on NFT marketplaces.
 */

contract ERC721Base is
    ERC721A,
    ContractMetadata,
    Ownable,
    BatchMintMetadata
{
    using TWStrings for uint256;

    address public manager;

    /*//////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => string) private fullURI;
    mapping(uint256 => uint256) public tokenToCollection;

    /*//////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address initialOwner
    ) Ownable(initialOwner) ERC721A(_name, _symbol) {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
    }

    /*//////////////////////////////////////////////////////////////
                            ERC165 Logic
    //////////////////////////////////////////////////////////////*/

    /// @dev See ERC165: https://eips.ethereum.org/EIPS/eip-165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721A) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        Overriden ERC721 logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice         Returns the metadata URI for an NFT.
     *  @dev            See `BatchMintMetadata` for handling of metadata in this contract.
     *
     *  @param _tokenId The tokenId of an NFT.
     */
    function tokenURI(
        uint256 _tokenId
    ) public view virtual override returns (string memory) {
        string memory fullUriForToken = fullURI[_tokenId];
        if (bytes(fullUriForToken).length > 0) {
            return fullUriForToken;
        }

        string memory batchUri = getBaseURI(_tokenId);
        return string(abi.encodePacked(batchUri, _tokenId.toString()));
    }

    // Function to set the token URI for a specific token ID
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        require(_canMint(), "Not allowed to set Token URI.");
        fullURI[tokenId] = _tokenURI;
    }


    /*//////////////////////////////////////////////////////////////
                            Minting logic
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice          Lets an authorized address mint an NFT to a recipient.
     *  @dev             The logic in the `_canMint` function determines whether the caller is authorized to mint NFTs.
     *
     *  @param _to       The recipient of the NFT to mint.
     *  @param _tokenURI The full metadata URI for the NFT minted.
     */
    function mintTo(
        uint256 blueprintId,
        address _to,
        string memory _tokenURI
    ) public virtual {
        require(_canMint(), "Not authorized to mint.");
        uint256 newTokenId = nextTokenIdToMint();
        fullURI[newTokenId] = _tokenURI;
        _safeMint(_to, 1, "");
        tokenToCollection[newTokenId] = blueprintId;
    }

    /**
     *  @notice         Lets an owner or approved operator burn the NFT of the given tokenId.
     *  @dev            ERC721A's `_burn(uint256,bool)` internally checks for token approvals.
     *
     *  @param _tokenId The tokenId of the NFT to burn.
     */
    function burn(uint256 _tokenId) external virtual {
        _burn(_tokenId, true);
    }

    /*//////////////////////////////////////////////////////////////
                        Public getters
    //////////////////////////////////////////////////////////////*/

    /// @notice The tokenId assigned to the next new NFT to be minted.
    function nextTokenIdToMint() public view virtual returns (uint256) {
        return _currentIndex;
    }

    /// @notice Returns whether a given address is the owner, or approved to transfer an NFT.
    function isApprovedOrOwner(
        address _operator,
        uint256 _tokenId
    ) public view virtual returns (bool isApprovedOrOwnerOf) {
        address owner = ownerOf(_tokenId);
        isApprovedOrOwnerOf = (_operator == owner ||
            isApprovedForAll(owner, _operator) ||
            getApproved(_tokenId) == _operator);
    }

    /*//////////////////////////////////////////////////////////////
                        Internal (overrideable) functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Returns whether contract metadata can be set in the given execution context.
    function _canSetContractURI()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }

    /// @dev Returns whether a token can be minted in the given execution context.
    function _canMint() internal view virtual returns (bool) {
        return msg.sender == owner() || msg.sender == manager;
    }

    /// @dev Returns whether owner can be set in the given execution context.
    function _canSetOwner() internal view virtual returns (bool) {
        return msg.sender == owner();
    }


    function _msgSender()
        internal
        view
        virtual
        override(ERC721A, Context)
        returns (address)
    {
        return msg.sender;
    }

    function _msgData()
        internal
        view
        virtual
        override(ERC721A, Context)
        returns (bytes calldata)
    {
        return msg.data;
    }
}
