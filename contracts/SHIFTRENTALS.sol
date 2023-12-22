// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";
import "./interface/IERC4907.sol";
import "hardhat/console.sol";
import "./SHIFTTOKEN.sol";
import "./SHIFTPROOFS.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTime.sol";

contract SHIFTRENTALS is ERC721Base, IERC4907 {
    using Strings for uint256;

    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }
    mapping(uint256 => UserInfo) internal _users;
    uint256 public pricePerHour = 0.01 ether;
    uint256 public earnableShiftTokenPerHour = 30;

    SHIFTTOKEN public shiftToken;
    SHIFTPROOFS public shiftProofs;

    event NewRental(
        uint256 tokenId,
        address user,
        uint64 expires,
        string collectionName,
        string employerName,
        address worker,
        uint256 earnedTokens
    );

    string internal artist = "Geraldine Honauer";

    constructor(
        address initialOwner,
        address _royaltyRecipient,
        uint128 _royaltyBps,
        address _shiftTokenAddress,
        address _shiftProofsAddress
    )
        ERC721Base(
            "SHIFTRENTALS",
            "SHR",
            _royaltyRecipient,
            _royaltyBps,
            initialOwner
        )
    {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
        shiftToken = SHIFTTOKEN(_shiftTokenAddress); // Initialize the SHIFTTOKEN contract
        shiftProofs = SHIFTPROOFS(_shiftProofsAddress); // Initialize the SHIFTTOKEN contract
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager of SHIFTRENTALS"
        );
        _;
    }

    function processUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) internal {
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
    }

    function mintProofNFT(
        address user,
        address worker,
        string memory collectionName,
        string memory employerName,
        string memory placeName,
        string memory wearableName,
        uint256 earnedTokens,
        uint64 expires
    ) public ownerOrMgr {
        (
            uint256 startYear,
            uint256 startMonth,
            uint256 startDay,
            uint256 startHour,
            uint256 startMinute,
            uint256 startSecond
        ) = DateTime.timestampToDateTime(block.timestamp);

        string memory startRentalDate = formatDateTime(
            startYear,
            startMonth,
            startDay,
            startHour,
            startMinute,
            true
        );

        string memory startRental = formatDateTime(
            startYear,
            startMonth,
            startDay,
            startHour,
            startMinute,
            false
        );
        (
            uint256 endYear,
            uint256 endMonth,
            uint256 endDay,
            uint256 endHour,
            uint256 endMinute,
            uint256 endSecond
        ) = DateTime.timestampToDateTime(expires / 1000);
        string memory endRental = formatDateTime(
            endYear,
            endMonth,
            endDay,
            endHour,
            endMinute,
            false
        );
        string memory rentalFee = etherToString(pricePerHour);
        uint256 remuneration = earnedTokens;

        shiftProofs.mint(
            user, // = renter
            worker,
            startRental,
            startRentalDate,
            endRental,
            rentalFee,
            collectionName,
            employerName,
            placeName,
            wearableName,
            remuneration,
            artist
        );
    }

    // only for testing and manager / owner to avoid fees
    function setUser(
        uint256 tokenId,
        address user, // the one renting the wearable
        address worker, // the worker
        uint64 expires,
        string memory collectionName, // Linz
        string memory employerName, // Ars Electronica
        string memory placeName, // POSTCITY
        string memory wearableName
    ) public virtual ownerOrMgr {
        // owner and manager can overwrite any user
        processUser(tokenId, user, expires);

        uint256 workedHours = calculateHoursDifference(expires);
        uint256 earnedTokens = earnableShiftTokenPerHour * workedHours;

        shiftToken.payoutTokens(user, earnedTokens);

        // mint proof to contract
        mintProofNFT(
            user,
            worker,
            collectionName,
            employerName,
            placeName,
            wearableName,
            earnedTokens,
            expires
        );

        emit NewRental(
            tokenId,
            user,
            expires,
            collectionName,
            employerName,
            worker,
            earnedTokens
        );
    }

    function payAndSetUser(
        uint256 tokenId,
        address user,
        address worker, // the worker
        uint64 expires,
        string memory collectionName, // Linz
        string memory employerName, // Ars Electronica
        string memory placeName, // POSTCITY
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

        // payout SHIFT tokens to the user as reward
        shiftToken.payoutTokens(user, earnedTokens);

        // payout 50% of rental fees to worker
        // TODO

        // mint proof to contract
        mintProofNFT(
            user,
            worker,
            collectionName,
            employerName,
            placeName,
            wearableName,
            earnedTokens,
            expires
        );

        emit NewRental(
            tokenId,
            user,
            expires,
            collectionName,
            employerName,
            worker,
            earnedTokens
        );
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
        string memory ethStr = Strings.toString(eth);
        string memory remainderStr = Strings.toString(remainder);

        // Padding the remainder if necessary
        if (remainder < 10) {
            remainderStr = string(abi.encodePacked("0", remainderStr));
        }

        // Concatenating the strings
        return string(abi.encodePacked(ethStr, ".", remainderStr, " ETH"));
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

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external override {}
}
