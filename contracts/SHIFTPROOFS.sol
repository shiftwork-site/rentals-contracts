// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract SHIFTPROOFS is Ownable, ERC721 {
    mapping(uint256 => address) private _tokenApprovals;

    event ProofOfRentMinted(uint256 tokenId);

    uint256 public tokenIdTracker;

    address public manager;

    // Global royalty settings
    address payable public globalRoyaltyRecipient;
    uint256 public globalRoyaltyPercentage = 10;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        address initialOwner,
        address payable _royaltyRecipient
    ) Ownable(initialOwner) ERC721("SHIFT PROOF OF RENTS", "SPR") {
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

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function contractURI() external pure returns (string memory) {
        string
            memory json = '{"name": "PROOF OF SHIFTWORK", "description": "Welcome to PROOF OF SHIFTWORK! This NFT collection resembles the receipts issued by SHIFT acknowledging that a blockchain-entity has rented the digital twin workwear of an actual museum worker </>SHIFT WEAR</> and performed labor of value in the Metaverse in their name. SHIFT is a performance-based media artwork that critically reflects on structures of value. The project investigates human labor by entangling the physical with the digital realm and transcoding actual corporate workwear into yielding digital assets. Learn more: </>SHIFTWORK.CC</>"}';

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(bytes(json))
                )
            );
    }

    function mint(
        address user,
        address worker,
        string memory startRental,
        string memory startRentalDate,
        string memory endRental,
        string memory rentalFee,
        string memory collection,
        string memory employer,
        string memory place,
        string memory wearable,
        uint256 remuneration,
        string memory artist
    ) external returns (uint256) {
        tokenIdTracker += 1;
        uint256 newTokenId = tokenIdTracker;

        string memory stringifiedWorker = Strings.toHexString(
            uint256(uint160(worker)),
            20
        );

        string memory stringifiedUser = Strings.toHexString(
            uint256(uint160(user)),
            20
        );

        string memory svgBase64 = Base64.encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 300">',
                '<text x="10" y="20">SHIFT Renter: ',
                stringifiedUser,
                "</text>",
                '<text x="10" y="40">Performer: ',
                stringifiedWorker,
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
                Strings.toString(remuneration),
                " SHIFT </text>",
                '<text x="10" y="180">Artist: ',
                artist,
                "</text>",
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
                startRentalDate,
                '"},',
                '{"trait_type":"EMPLOYER", "value":"',
                employer,
                '"},',
                '{"trait_type":"PLACE", "value":"',
                place,
                '"},',
                '{"trait_type":"WORKWEAR", "value":"',
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
                "This on-chain generated NFT is proof that ",
                stringifiedUser,
                " performed labor of value in the Metaverse by renting the digital twin workwear of ",
                wearable,
                " during their shifts for ",
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
        console.log(finalUri);
        _tokenURIs[newTokenId] = finalUri;

        _mint(address(this), newTokenId);
        _tokenApprovals[newTokenId] = user;

        emit ProofOfRentMinted(newTokenId);

        return newTokenId;
    }

    function claim(uint256 tokenId) public {
        require(
            _tokenApprovals[tokenId] == msg.sender,
            "Caller not approved to claim this token"
        );
        _approve(msg.sender, tokenId, address(this));
        transferFrom(address(this), msg.sender, tokenId);

        delete _tokenApprovals[tokenId];
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
