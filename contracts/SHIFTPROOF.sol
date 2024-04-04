// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "hardhat/console.sol";
import "./DateTime.sol";

contract SHIFTPROOF is Ownable, ERC721, ERC721Royalty {
    using Strings for uint256;

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
    ) Ownable(initialOwner) ERC721("SHIFT PROOF", "SHP") ERC721Royalty() {
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

        (
            uint256 startYear,
            uint256 startMonth,
            uint256 startDay,
            uint256 startHour,
            uint256 startMinute,
            uint256 startSecond
        ) = DateTime.timestampToDateTime(startRental);

        string memory startRentalDate = formatDateTime(
            startYear,
            startMonth,
            startDay,
            startHour,
            startMinute,
            true
        );

  
        string memory iString = generateIString(remuneration);

        string memory svgBase64 = Base64.encode(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="1000" height="1000"><style><![CDATA[text{transform-origin:center}.A{animation:spin 180000ms linear infinite}.B{animation:spin 150000ms linear infinite}.C{animation:spin 120000ms linear infinite}.D{animation:spin 210000ms linear infinite}.E{animation:spin 90000ms linear infinite}@keyframes spin{to{transform:rotate(360deg)}}.F{font-family:Arial}.G{font-size:3.5rem}]]></style><defs><path id="A" d="M75 500a425 425 0 0 1 850 0 425 425 0 0 1-850 0"/><path id="B" d="M125 500a375 375 0 0 1 750 0 375 375 0 0 1-750 0"/><path id="C" d="M175 500a325 325 0 0 1 650 0 325 325 0 0 1-650 0"/><path id="D" d="M225 500a275 275 0 0 1 550 0 275 275 0 0 1-550 0"/></defs>',
                '<text class="A F G" fill="#333333"><textPath xlink:href="#A">',
                iString,
                '</textPath></text><text class="B F G" fill="#', getFirstSixLetters(startRentalStr),'"><textPath xlink:href="#B">',
                startRentalStr,
                " - ", 
               '</textPath></text><text class="B F G" x="355" fill="#', getFirstSixLetters(endRental),'"><textPath xlink:href="#B">', endRental,
                '</textPath></text><text class="C F G" fill="#',
                getFirst6Digits(user),
                '"><textPath xlink:href="#C">',
                stringifiedUser,
                '</textPath></text><text class="D F G" fill="#',
                getFirst6Digits(worker),
                '"><textPath xlink:href="#D">',
                stringifiedWorker,
                '</textPath></text><text class="E F" x="50%" y="55%" text-anchor="middle" font-size="6.5rem" fill="#',
                getFirst6Digits(address(this)), 
                '" font-weight="bold">SHIFT</text></svg>'
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
                '{"trait_type":"WORKER", "value":"',
                wearable,
                '"}',
                "]"
            )
        );

        string memory name = string(abi.encodePacked(wearable, " SHIFT WORK"));

        string memory description = string(
            abi.encodePacked(
                "This on-chain generated proof-of-work NFT certfifies that ",
                stringifiedUser,
                " has conducted labor of value in the Metaverse by performing the digital twin of the uniform ",
                wearable,
                " performed during their shifts as a museum supervisor at ",
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

    function byteToHexChar(bytes1 b) internal pure returns (string memory) {
        bytes memory hexChars = "0123456789abcdef";
        // Extracting the top and bottom half of the byte
        bytes memory result = new bytes(2);
        result[0] = hexChars[uint8(b) >> 4];
        result[1] = hexChars[uint8(b) & 0x0f];
        return string(result);
    }

  function getFirstSixLetters(string memory _str) public pure returns (string memory) {
        bytes memory strBytes = bytes(_str);
        require(strBytes.length >= 6, "String is too short");

        bytes memory result = new bytes(6);
        for (uint i = 0; i < 6; i++) {
            result[i] = strBytes[i];
        }
        
        return string(result);
    }


    function getFirst6Digits(address _addr) public pure returns (string memory) {
        bytes3 firstThreeBytes = bytes3(bytes20(_addr));
        // Convert each of the first 3 bytes to a hexadecimal string
        string memory hexStr = string(abi.encodePacked(
            byteToHexChar(firstThreeBytes[0]),
            byteToHexChar(firstThreeBytes[1]),
            byteToHexChar(firstThreeBytes[2])
        ));
        return hexStr;
    }

    function monthToString(
        uint256 _month
    ) internal pure returns (string memory) {
        string[12] memory months = [
            "Jan",
            "Feb",
            "Mar",
            "Apr",
            "May",
            "Jun",
            "Jul",
            "Aug",
            "Sep",
            "Oct",
            "Nov",
            "Dec"
        ];
        return months[_month - 1];
    }

    function formatDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        bool withoutTime
    ) internal pure returns (string memory) {
        string memory yearStr = year.toString();
        string memory monthStr = monthToString(month);
        string memory dayStr = day < 10
            ? string(abi.encodePacked("0", day.toString()))
            : day.toString();
        string memory hourStr = hour < 10
            ? string(abi.encodePacked("0", hour.toString()))
            : hour.toString();
        string memory minuteStr = minute < 10
            ? string(abi.encodePacked("0", minute.toString()))
            : minute.toString();

        if (withoutTime) {
            return
                string(abi.encodePacked(dayStr, " ", monthStr, " ", yearStr));
        }
        return
            string(
                abi.encodePacked(
                    dayStr,
                    " ",
                    monthStr,
                    " ",
                    yearStr,
                    " ",
                    hourStr,
                    ":",
                    minuteStr
                )
            );
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
