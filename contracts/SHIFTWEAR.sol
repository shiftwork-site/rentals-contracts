// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";
import "./interface/IERC4907.sol";
import "./SHIFTTOKEN.sol";
import "./SHIFTPROOFS.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SHIFTWEAR is ERC721Base, IERC4907 {
    using Strings for uint256;

    struct UserInfo {
        address user;
        uint256 expires; 
    }
    mapping(uint256 => UserInfo) internal _users;
    uint256 public pricePerHour = 0.01 ether;
    uint256 public earnableShiftTokenPerHour = 30;

    SHIFTTOKEN public shiftToken;
    SHIFTPROOFS public shiftProofs;

    event NewRental(
        uint256 tokenId,
        uint256 proofTokenId,
        address user,
        uint256 expires,
        string collectionName,
        string employerName,
        address worker,
        uint256 earnedTokens
    );


    constructor(
        address initialOwner,
        address _royaltyRecipient,
        address _shiftTokenAddress,
        address _shiftProofsAddress
    )
        ERC721Base(
            "SHIFT WEAR",
            "SHW",
            _royaltyRecipient,
            initialOwner
        )
    {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
        shiftToken = SHIFTTOKEN(_shiftTokenAddress); 
        shiftProofs = SHIFTPROOFS(_shiftProofsAddress); 
        
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager of SHIFTWEAR"
        );
        _;
    }

    function processUser(
        uint256 tokenId,
        address user,
        uint256 expires
    ) internal {
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
    }

    function payAndSetUser(
        uint256 tokenId,
        address payable worker,
        uint256 userHours,
        string memory collectionName, 
        string memory employerName, 
        string memory placeName, 
        string memory wearableName
    ) external payable {
        uint256 expires = block.timestamp + (userHours * 1 hours);

        require(msg.value > 0, "No ETH sent");

        address user = msg.sender;

        require(userHours <= 8, "8 hrs is max");
        uint256 earnedTokens = earnableShiftTokenPerHour * userHours;

        uint256 amountToPay = pricePerHour * userHours;

        require(msg.value >= amountToPay, "Not enough ETH sent");

        require(
            _users[tokenId].user == address(0) ||
                ((_users[tokenId].expires / 1000) < block.timestamp),
            "User already set and not expired"
        );

        processUser(tokenId, user, expires);

        shiftToken.payoutTokens(user, earnedTokens);

        uint256 workerPayment = msg.value / 2;
        worker.transfer(workerPayment);

       string memory rentalFee = etherToString(pricePerHour);
        uint256 remuneration = earnedTokens;

        uint256 proofTokenId = shiftProofs.mint(
            user, // = renter
            Strings.toString(expires),
            rentalFee,
            collectionName,
            employerName,
            placeName,
            wearableName,
            remuneration
        );

        emit NewRental(
            tokenId,
            proofTokenId,
            user,
            expires,
            collectionName,
            employerName,
            worker,
            earnedTokens
        );
    }

    function userOf(uint256 tokenId) external view virtual returns (address) {
        if ((uint256(_users[tokenId].expires)) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    // TODO test
    function withdraw(
        address payable recipient,
        uint256 amount
    ) external ownerOrMgr {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function userExpires(
        uint256 tokenId
    ) external view virtual returns (uint256) {
        return _users[tokenId].expires;
    }


    function etherToString(
        uint256 amount
    ) internal pure returns (string memory) {
        uint256 ethInTwoDecimals = amount / 1e16;
        uint256 integerPart = ethInTwoDecimals / 100;
        uint256 decimalPart = ethInTwoDecimals % 100;

        string memory integerPartStr = Strings.toString(integerPart);
        string memory decimalPartStr = decimalPart < 10
            ? string(abi.encodePacked("0", Strings.toString(decimalPart)))
            : Strings.toString(decimalPart);
        return
            string(
                abi.encodePacked(integerPartStr, ".", decimalPartStr, " ETH")
            );
    }

    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) external override {}
}
