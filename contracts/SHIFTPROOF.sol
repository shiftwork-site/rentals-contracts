// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "hardhat/console.sol";

contract SHIFTPROOF is Ownable, ERC721, ERC721Royalty {
    mapping(uint256 => address) public tokenApprovals;
    mapping(uint256 => uint256) private _startRentalTimestamps;

    event ProofOfRentMinted(uint256 tokenId);

    uint256 public tokenIdTracker;

    address public manager;

    address public allowedContract;

    mapping(uint256 => string) private _tokenURIs;

    constructor(
        address initialOwner,
        address payable _royaltyRecipient
    )
        Ownable(initialOwner)
        ERC721("SHIFT PROOF", "SHP")
        ERC721Royalty()
    {
        _setDefaultRoyalty(_royaltyRecipient, 1000);
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
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

    function generateIString(
        uint256 remuneration
    ) internal pure returns (string memory) {
        bytes memory b = new bytes(remuneration);
        for (uint i = 0; i < remuneration; i++) {
            b[i] = "I"; 
        }
        return string(b);
    }

    function stringifyAddress(
        address myAddress
    ) internal pure returns (string memory) {
        return Strings.toHexString(uint256(uint160(myAddress)), 20);
    }

    function mint(
        address worker,
        address user,
        string memory endRental,
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

        string memory stringifiedUser = stringifyAddress(user);
        string memory stringifiedWorker = stringifyAddress(worker);

        uint256 startRental = block.timestamp;
        string memory startRentalStr = Strings.toString(startRental);

        string memory iString = generateIString(remuneration);

string memory svgBase64 = Base64.encode(
    abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1000" height="1000" xmlns:v="https://vecta.io/nano">',
        "<style><![CDATA[",
        "text{transform-origin:center; font-family:Arial; font-size:3.5rem; fill:black;}",  
        "@keyframes rotate { to { transform: rotate(360deg); } }", 
        ".rotate { animation: rotate 90000ms linear infinite; }", 
        "]]></style>",
        "<defs>",
        '<path id="A" d="M75 500a425 425 0 0 1 850 0 425 425 0 0 1-850 0"/>',
        '<path id="B" d="M125 500a375 375 0 0 1 750 0 375 375 0 0 1-750 0"/>',
        '<path id="C" d="M175 500a325 325 0 0 1 650 0 325 325 0 0 1-650 0"/>',
        '<path id="D" d="M225 500a275 275 0 0 1 550 0 275 275 0 0 1-550 0"/>',
        "</defs>",
        '<text><textPath xlink:href="#A">', 
        iString,
        "</textPath></text>",
        '<text><textPath xlink:href="#B">', 
        startRentalStr,
        " - ",
        endRental,
        "</textPath></text>",
        '<text><textPath xlink:href="#C">', 
        stringifiedUser,
        "</textPath></text>",
        '<text><textPath xlink:href="#D">', 
        stringifiedWorker,
        "</textPath></text>",
        '<text class="rotate" x="50%" y="55%" text-anchor="middle" font-size="6.5rem" fill="#000" font-weight="bold">SHIFT</text>',
        "</svg>"
    )
);     string memory attributes = string(
            abi.encodePacked(
                '", "attributes":[',
                '{"trait_type":"COLLECTION", "value":"',
                collection,
                '"},',
                '{"trait_type":"DATE", "value":"',
                startRentalStr,
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
                "]"
            )
        );

        string memory name = string(abi.encodePacked(wearable, " SHIFT WORK"));

        string memory description = string(
            abi.encodePacked(
                "This on-chain generated proof-of-work NFT certifies that the renter ",
                stringifiedUser,
                " has performed labor of value in the METAVERSE wearing the digital twin of the uniform ",
                wearable,
                " wore during their shifts as a museum supervisor at ",
                collection,
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
        console.log(json);
        string memory finalUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        _tokenURIs[newTokenId] = finalUri;

        _mint(address(this), newTokenId);
        tokenApprovals[newTokenId] = user;
        _startRentalTimestamps[newTokenId] = startRental;

        emit ProofOfRentMinted(newTokenId);

        return newTokenId;
    }

    function claim(uint256 tokenId) external {
        require(
            block.timestamp <= _startRentalTimestamps[tokenId] + 7776000,
            "Claim period exceeded 90 days after start rental"
        );

        require(
            tokenApprovals[tokenId] == msg.sender,
            "Caller not approved to claim this token"
        );
        _approve(msg.sender, tokenId, address(this));
        transferFrom(address(this), msg.sender, tokenId);

        delete tokenApprovals[tokenId];
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721) returns (string memory) {
        return _tokenURIs[tokenId];
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, ERC721Royalty) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
