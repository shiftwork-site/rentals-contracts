// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "./Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

contract SHIFTPROOFS is ERC1155, Ownable {
    address public manager;
    string public name = "SHIFT PROOF OF RENTS";

    event TokenMinted(uint256 tokenId, address minter);

    uint256 public tokenIdTracker;

    // Global royalty settings
    address payable public globalRoyaltyRecipient;
    uint256 public globalRoyaltyPercentage = 10;

    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => uint256) public tokenMintCount;
    mapping(uint256 => uint256) public tokenMinterCount;
    mapping(uint256 => mapping(address => bool)) private hasMinted;
    mapping(uint256 => uint256) public tokenToCollection;

    constructor(address payable _royaltyRecipient) ERC1155("") {
        _setupOwner(msg.sender);
        manager = 0x5eB336F4FfF71e31e378948Bf2B07e6BffDc7C86;
        globalRoyaltyRecipient = _royaltyRecipient;
    }

    function contractURI() external pure returns (string memory) {
        string
            memory json = '{"name": "SHIFT PROOF OF RENTS","description": "Claim an on-chain proof-of-rent NFT artwork capturing your metaverse performance."}';
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager"
        );
        _;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function createProofNFT(
        uint256 blueprintId,
        string memory metadataURI
    ) external ownerOrMgr returns (uint256) {

        tokenIdTracker += 1;
        uint256 newTokenId = tokenIdTracker;

        _tokenURIs[newTokenId] = metadataURI;

        _mint(msg.sender, newTokenId, 1, "");

        emit TokenMinted(newTokenId, msg.sender);

        tokenToCollection[newTokenId] = blueprintId;

        tokenMintCount[newTokenId]++;

        hasMinted[newTokenId][msg.sender] = true;
        tokenMinterCount[newTokenId]++;

        return newTokenId;
    }

    function mint(address account, uint256 tokenId, uint256 amount) public {
        // uint256 blueprintId = tokenToCollection[tokenId];

        // maybe enable later
        // require(
        //     collections[blueprintId].mintingEnabled,
        //     "Minting is not enabled for this collection."
        // );

        _mint(account, tokenId, amount, "");
        tokenMintCount[tokenId]++;

        if (!hasMinted[tokenId][account]) {
            hasMinted[tokenId][account] = true;
            tokenMinterCount[tokenId]++;
        }
        emit TokenMinted(tokenId, account);
    }

    function royaltyInfo(
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (salePrice * globalRoyaltyPercentage) / 10000;
        return (globalRoyaltyRecipient, royaltyAmount);
    }

    function setTokenURI(
        uint256 tokenId,
        string memory newURI
    ) external ownerOrMgr {
        require(
            bytes(_tokenURIs[tokenId]).length > 0,
            "Token ID does not exist"
        );
        _tokenURIs[tokenId] = newURI;
    }

    function uri(uint256 tokenId) public view override returns (string memory) {
        return _tokenURIs[tokenId];
    }

    function _canSetOwner() internal virtual override returns (bool) {}
}
