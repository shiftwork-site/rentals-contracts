// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Base.sol";
import "./interface/IERC4907.sol";
import "hardhat/console.sol";

contract SHIFTRENTALS is ERC721Base, IERC4907 {
    struct UserInfo {
        address user; // address of user role
        uint64 expires; // unix timestamp, user expires
    }
    address public manager;
    mapping(uint256 => UserInfo) internal _users;
    uint256 public pricePerHour = 100000000000000000; // 0.1 ether in wei

    constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    ) ERC721Base(_name, _symbol, _royaltyRecipient, _royaltyBps) {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
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

   
    function setUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public virtual ownerOrMgr {
        // owner and manager can overwrite any user
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

     function payAndSetUser(
        uint256 tokenId,
        address user,
        uint64 expires
    ) public payable {
        require(expires >= block.timestamp, "Timestamp is in the past");
        require(msg.value > 0, "No ETH sent");

        // TODO check if correct amount was sent
        // require(msg.value == getPricePerHourInEther() * calculateHoursDifference(expires), "Not enough ETH sent");
        
        // Check if user is already set and not expired
        console.log(_users[tokenId].user);
        console.log(_users[tokenId].expires);
        console.log(address(0));
        require(_users[tokenId].user == address(0) || _users[tokenId].expires < block.timestamp, "User already set and not expired");

        // Set user after payment is successful
        UserInfo storage info = _users[tokenId];
        info.user = user;
        info.expires = expires;
        emit UpdateUser(tokenId, user, expires);
    }

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) public view virtual returns (address) {
        if (uint256(_users[tokenId].expires) >= block.timestamp) {
            return _users[tokenId].user;
        } else {
            return address(0);
        }
    }

    function calculateHoursDifference(uint256 timestamp) public view returns (uint256) {
        uint256 differenceInSeconds = timestamp - block.timestamp;
        uint256 differenceInHours = differenceInSeconds / 1 hours;
        return differenceInHours;
    }

    function getPricePerHourInEther() public view returns (uint256) {
    return pricePerHour / 1 ether;
}

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId)
        public
        view
        virtual
        returns (uint256)
    {
        return _users[tokenId].expires;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC4907).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}