// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";
import "./interface/IERC4907.sol";
import "hardhat/console.sol";
import "./SHIFTTOKEN.sol";
import "./SHIFTPROOFS.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SHIFTRENTALS is ERC721Base, IERC4907 {
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }
    address public manager;
    mapping(uint256 => UserInfo) internal _users;
    uint256 public pricePerHour = 0.01 ether;
    uint256 public earnableShiftTokenPerHour = 30;

    SHIFTTOKEN public shiftToken;
    SHIFTPROOFS public shiftProofs;

    event NewRental(uint256 tokenId, address user, uint64 expires);

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _shiftTokenAddress,
        address _shiftProofsAddress
    ) ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;

        shiftToken = SHIFTTOKEN(_shiftTokenAddress); // Initialize the SHIFTTOKEN contract
        shiftProofs = SHIFTPROOFS(_shiftProofsAddress); // Initialize the SHIFTTOKEN contract
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager of SHIFTRENTALS"
        );
        _;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function processUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) internal {
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit NewRental(tokenId, user, expires);
    }

    function mintProofNFT(
        address user,
        string memory collectionName,
        string memory wearableName,
        uint256 earnedTokens
    ) public {
        // string memory renter = "Ox";
        string memory renter = Strings.toHexString(
            uint256(uint160(owner())),
            20
        ); // not sure

        string memory startRental = "03 Sep 2023 14:12";
        string memory endRental = "03 Sep 2023 15:12";
        string memory rentalFee = etherToString(pricePerHour);
        string memory collection = collectionName;
        string memory wearable = wearableName;
        uint256 remuneration = earnedTokens;
        string memory artist = "Geraldine Honauer";

        shiftProofs.mint(
            renter,
            user, // = performer
            startRental,
            endRental,
            rentalFee,
            collection,
            wearable,
            remuneration,
            artist
        );
    }

    // only for testing and manager / owner to avoid fees
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        string memory collectionName,
        string memory wearableName
    ) public virtual ownerOrMgr {
        // owner and manager can overwrite any user
        processUser(tokenId, user, expires);

        uint256 workedHours = calculateHoursDifference(expires);
        uint256 earnedTokens = earnableShiftTokenPerHour * workedHours;

        shiftToken.setWhitelistAmount(user, earnedTokens);
        mintProofNFT(user, collectionName, wearableName, earnedTokens);
    }

    function payAndSetUser(
        uint256 tokenId,
        address user,
        uint64 expires,
        string memory collectionName,
        string memory wearableName
    ) public payable {
        require(
            (expires / 1000) >= block.timestamp,
            "Timestamp is in the past"
        );
        require(msg.value > 0, "No ETH sent");

        uint256 workedHours = calculateHoursDifference(expires);
        uint256 earnedTokens = earnableShiftTokenPerHour * workedHours;

        uint256 amountToPay = pricePerHour * workedHours;
        console.log("amountToPay ", amountToPay); // in wei

        // TODO check if correct amount was sent
        // require(msg.value == amountToPay, "Not enough ETH sent");

        // Check if user is already set and not expired
        require(
            _users[tokenId].user == address(0) ||
                ((_users[tokenId].expires / 1000) < block.timestamp),
            "User already set and not expired"
        );

        // Set user after payment is successful
        processUser(tokenId, user, expires);

        shiftToken.setWhitelistAmount(user, earnedTokens);

        mintProofNFT(user, collectionName, wearableName, earnedTokens);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if ((uint256(_users[tokenId].expires / 1000)) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    function calculateHoursDifference(
        uint256 timestampInMilliseconds
    ) public view returns (uint256) {
        uint256 differenceInSeconds = timestampInMilliseconds /
            1000 -
            block.timestamp;
        uint256 differenceInHours = differenceInSeconds / 1 hours;
        console.log("differenceInHours", differenceInHours);
        return differenceInHours;
    }

    // TODO probably broken!!!!
    function withdraw(
        address payable recipient,
        uint256 amount
    ) public ownerOrMgr {
        require(amount <= address(this).balance, "Insufficient balance");

        // Transfer the specified amount to the recipient
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(
        uint256 tokenId
    ) public view virtual returns (uint256) {
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function etherToString(uint256 amount) public pure returns (string memory) {
        // Assuming the amount is in Wei
        uint256 eth = amount / 1e18;
        uint256 remainder = (amount - (eth * 1e18)) / 1e16; // Getting two decimal places

        // Converting the integer parts to strings
        string memory ethStr = uintToString(eth);
        string memory remainderStr = uintToString(remainder);

        // Padding the remainder if necessary
        if (remainder < 10) {
            remainderStr = string(abi.encodePacked("0", remainderStr));
        }

        // Concatenating the strings
        return string(abi.encodePacked(ethStr, ".", remainderStr, " ETH"));
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        // Convert a uint to a string
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external override {}
}
