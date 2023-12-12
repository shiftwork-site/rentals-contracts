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

    function mint(
        string memory renter,
        string memory performer,
        string memory startRental,
        string memory endRental,
        string memory rentalFee,
        string memory collection,
        string memory wearable,
        uint256 remuneration,
        string memory artist
    ) external returns (uint256) {
        tokenIdTracker += 1;
        uint256 newTokenId = tokenIdTracker;

        _tokenURIs[newTokenId] = _constructTokenURI(
            newTokenId,
            renter,
            performer,
            startRental,
            endRental,
            rentalFee,
            collection,
            wearable,
            remuneration,
            artist
        );

        _mint(msg.sender, newTokenId, 1, "");

        emit TokenMinted(newTokenId, msg.sender);

        return newTokenId;
    }

    function _constructTokenURI(
        uint256 tokenId,
        string memory renter,
        string memory performer,
        string memory startRental,
        string memory endRental,
        string memory rentalFee,
        string memory collection,
        string memory wearable,
        uint256 remuneration,
        string memory artist
    ) internal view returns (string memory) {
        // only working with ERC721
        // require(_exists(tokenId), "Nonexistent token.");

        string memory svgBase64 = Base64.encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 300">',
                '<text x="10" y="20">Renter: ',
                renter,
                "</text>",
                '<text x="10" y="40">Performer: ',
                performer,
                "</text>",
                '<text x="10" y="60">Start Rental: ',
                startRental,
                "</text>",
                '<text x="10" y="80">End Rental: ',
                endRental,
                "</text>",
                '<text x="10" y="100">Rental fee: ',
                rentalFee,
                "</text>",
                '<text x="10" y="120">Collection: ',
                collection,
                "</text>",
                '<text x="10" y="140">Wearable: ',
                wearable,
                "</text>",
                '<text x="10" y="160">Remuneration: ',
                uintToString(remuneration),
                " SHIFT </text>",
                '<text x="10" y="180">Artist: ',
                artist,
                "</text>",
                "</svg>"
            )
        );
        string memory attributes = string(
            abi.encodePacked('", "attributes":[]"')
        );

        string memory name = string(abi.encodePacked("Proof of Rent"));
        string memory description = string(
            abi.encodePacked("ColorHueState Block #")
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"',
                        name,
                        '", "description":"',
                        description,
                        '", "image":"data:image/svg+xml;base64,',
                        svgBase64,
                        attributes,
                        " }"
                    )
                )
            )
        );
        string memory finalUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        console.log(finalUri);
        return finalUri;
    }

    // function createProofNFT(
    //     uint256 blueprintId,
    //     string memory metadataURI
    // ) external ownerOrMgr returns (uint256) {

    //     tokenIdTracker += 1;
    //     uint256 newTokenId = tokenIdTracker;

    //     _tokenURIs[newTokenId] = metadataURI;

    //     _mint(msg.sender, newTokenId, 1, "");

    //     emit TokenMinted(newTokenId, msg.sender);

    //     tokenToCollection[newTokenId] = blueprintId;

    //     tokenMintCount[newTokenId]++;

    //     hasMinted[newTokenId][msg.sender] = true;
    //     tokenMinterCount[newTokenId]++;

    //     return newTokenId;
    // }

    // function mint(address account, uint256 tokenId, uint256 amount) public {
    //     // uint256 blueprintId = tokenToCollection[tokenId];

    //     // maybe enable later
    //     // require(
    //     //     collections[blueprintId].mintingEnabled,
    //     //     "Minting is not enabled for this collection."
    //     // );

    //     _mint(account, tokenId, amount, "");
    //     tokenMintCount[tokenId]++;

    //     if (!hasMinted[tokenId][account]) {
    //         hasMinted[tokenId][account] = true;
    //         tokenMinterCount[tokenId]++;
    //     }
    //     emit TokenMinted(tokenId, account);
    // }

        function uintToString(uint256 value) public pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 length;
        while (temp != 0) {
            length++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(length);
        while (value != 0) {
            length--;
            buffer[length] = bytes1(uint8(48 + (value % 10)));
            value /= 10;
        }
        return string(buffer);
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
