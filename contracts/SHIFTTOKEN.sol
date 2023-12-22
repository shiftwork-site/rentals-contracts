// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHIFTTOKEN is ERC20, Ownable {
    uint256 public constant INITIAL_SUPPLY = 100 * 10 ** 18; // assuming 18 decimals
    uint256 public airdroppedAmount = 0;
    // uint256 public withdrawnAmount = 0;
    uint256 public payoutAmount = 0;

    uint256 public constant RESERVED_FOR_AIRDROPS = (INITIAL_SUPPLY * 10) / 100;
    uint256 public constant RESERVED_FOR_PAYOUTS = (INITIAL_SUPPLY * 70) / 100;
    uint256 public constant RESERVED_FOR_OWNER_AND_MANAGER =
        (INITIAL_SUPPLY * 20) / 100;

    address public manager;

    constructor(
        address initialOwner
    ) Ownable(initialOwner) ERC20("SHIFT", "SHIFT") {
        manager = 0x4a7D0d9D2EE22BB6EfE1847CfF07Da4C5F2e3f22;
        _mint(address(this), RESERVED_FOR_OWNER_AND_MANAGER);
        _mint(owner(), 2 * 10 ** 18); // withdrawals only allowed for wallets with at least 1 token
        _mint(manager, 1 * 10 ** 18); // withdrawals only allowed for wallets with at least 1 token
    }

    modifier ownerOrMgr() {
        require(
            msg.sender == owner() || msg.sender == manager,
            "Not owner or manager of SHIFTTOKEN"
        );
        _;
    }

    function setManager(address _manager) external ownerOrMgr {
        manager = _manager;
    }

    function withdraw(
        address payable recipient,
        uint256 amount
    ) public ownerOrMgr {
        require(
            amount * 10 ** 18 <= balanceOf(address(this)),
            "Insufficient balance"
        );
        recipient.transfer(amount * 10 ** 18);
        // withdrawnAmount = withdrawnAmount + amount;
    }

    function airdropTokens(address to, uint256 amount) public ownerOrMgr {
        require(
            amount < RESERVED_FOR_AIRDROPS - airdroppedAmount,
            "No tokens left for airdops"
        );
        _mint(to, amount * 10 ** 18);
        airdroppedAmount = airdroppedAmount + amount * 10 ** 18;
    }

    function payoutTokens(address to, uint256 amount) public {
        require(
            amount < RESERVED_FOR_PAYOUTS - payoutAmount,
            "No tokens left for payouts"
        );
        _mint(to, amount);
        payoutAmount = payoutAmount + amount;
    }
}
