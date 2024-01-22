// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SHIFTPROOFS is Ownable, ERC721 {
    mapping(uint256 => address) public tokenApprovals;

    event ProofOfRentMinted(uint256 tokenId);

    uint256 public tokenIdTracker;

    address public manager;

    address payable public globalRoyaltyRecipient;
    uint256 public globalRoyaltyPercentage = 10;

    address public allowedContract;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        address initialOwner,
        address payable _royaltyRecipient
    ) Ownable(initialOwner) ERC721("PROOF OF SHIFTWORK", "SHP") {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
        globalRoyaltyRecipient = _royaltyRecipient;
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager of SHIFTPROOFS"
        );
        _;
    }

    function setAllowedContract(address _contract) external ownerOrMgr {
        allowedContract = _contract;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function mint(
        address user,
        string memory startRental,
        string memory endRental,
        string memory rentalFee,
        string memory collection,
        string memory employer,
        string memory place,
        string memory wearable,
        uint256 remuneration
    ) external returns (uint256) {
        require(
            msg.sender == allowedContract ||
                msg.sender == manager ||
                msg.sender == owner(),
            "Not owner or manager or allowed contract to mint"
        );
        tokenIdTracker += 1;
        uint256 newTokenId = tokenIdTracker;

        string memory stringifiedUser = Strings.toHexString(
            uint256(uint160(user)),
            20
        );

        string memory svgBase64 = Base64.encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="300" height="600" viewBox="0 0 300 600">',
                "<style>",
                'text { font-family: "monospace", sans-serif; }',
                "</style>",
                '<rect width="300" height="600" fill="white"/>'
                '<text x="10" y="80">RENTER: ',
                user,
                "</text>",
                '<text x="10" y="110">WORKER: ',
                wearable,
                "</text>",
                '<text x="10" y="140">UNIX TIME : ',
                endRental,
                "</text>",
                '<text x="10" y="170">RENTAL FEE: ',
                rentalFee,
                "</text>",
                '<text x="10" y="200">COLLECTION: ',
                collection,
                "</text>",
                '<text x="10" y="230">REMUNERATION: ',
                Strings.toString(remuneration),
                " SHIFT </text>",
                '<text x="10" y="260">ARTIST: Geraldine Honauer</text>',
                "</svg>"
            )
        );

        string memory attributes = string(
            abi.encodePacked(
                '", "attributes":[',
                '{"trait_type":"COLLECTION", "value":"',
                collection,
                '"},',
                '{"trait_type":"DATE", "value":"',
                startRental,
                '"},',
                '{"trait_type":"EMPLOYER", "value":"',
                employer,
                '"},',
                '{"trait_type":"PLACE", "value":"',
                place,
                '"},',
                '{"trait_type":"WORKER", "value":"',
                wearable,
                '"},',
                '{"trait_type":"RENTER", "value":"',
                stringifiedUser,
                '"}',
                "]"
            )
        );

        string memory name = string(abi.encodePacked(wearable, " Shiftwork"));

        string memory description = string(
            abi.encodePacked(
                "This on-chain generated proof-of-work NFT certifies that the renter ",
                stringifiedUser,
                " has performed labor of value in the Metaverse wearing the digital twin of the uniform ",
                wearable,
                " wore during their shifts as a museum supervisor at ",
                collection,
                " at ",
                place,
                " in ",
                employer,
                "."
            )
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
        _tokenURIs[newTokenId] = finalUri;

        _mint(address(this), newTokenId);
        tokenApprovals[newTokenId] = user;


        emit ProofOfRentMinted(newTokenId);

        return newTokenId;
    }

    function claim(uint256 tokenId) external {
        require(
            tokenApprovals[tokenId] == msg.sender,
            "Caller not approved to claim this token"
        );
        _approve(msg.sender, tokenId, address(this)); // needed?
        transferFrom(address(this), msg.sender, tokenId);

        delete tokenApprovals[tokenId];
    }

    function royaltyInfo(
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount) {
        royaltyAmount = (salePrice * globalRoyaltyPercentage) / 10000;
        return (globalRoyaltyRecipient, royaltyAmount);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return _tokenURIs[tokenId];
    }
}
